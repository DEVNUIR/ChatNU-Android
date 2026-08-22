package com.example.remote

import android.content.Context
import android.media.AudioManager
import com.example.model.Conversation
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import org.webrtc.AudioSource
import org.webrtc.AudioTrack
import org.webrtc.Camera2Enumerator
import org.webrtc.CameraEnumerator
import org.webrtc.DataChannel
import org.webrtc.DefaultVideoDecoderFactory
import org.webrtc.DefaultVideoEncoderFactory
import org.webrtc.EglBase
import org.webrtc.IceCandidate
import org.webrtc.MediaConstraints
import org.webrtc.MediaStream
import org.webrtc.PeerConnection
import org.webrtc.PeerConnectionFactory
import org.webrtc.RtpReceiver
import org.webrtc.SdpObserver
import org.webrtc.SessionDescription
import org.webrtc.SurfaceTextureHelper
import org.webrtc.SurfaceViewRenderer
import org.webrtc.VideoCapturer
import org.webrtc.VideoSource
import org.webrtc.VideoTrack
import java.util.UUID

enum class CallPhase { IDLE, INCOMING, CONNECTING, ACTIVE, ENDED, ERROR }

data class CallUiState(
    val phase: CallPhase = CallPhase.IDLE,
    val callId: String? = null,
    val conversationId: String? = null,
    val peerUserId: String? = null,
    val peerName: String = "",
    val video: Boolean = false,
    val outgoing: Boolean = false,
    val muted: Boolean = false,
    val cameraEnabled: Boolean = true,
    val speakerEnabled: Boolean = true,
    val error: String? = null
)

/** One-to-one WebRTC calling. Signaling is authenticated by the ChatNU websocket. */
class WebRtcCallManager(
    private val context: Context,
    private val chatRepository: RemoteChatRepository,
    private val authRepository: RemoteAuthRepository
) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private val eglBase = EglBase.create()
    private val factory: PeerConnectionFactory
    private val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager

    private val _state = MutableStateFlow(CallUiState())
    val state: StateFlow<CallUiState> = _state.asStateFlow()

    private var peerConnection: PeerConnection? = null
    private var audioSource: AudioSource? = null
    private var audioTrack: AudioTrack? = null
    private var videoSource: VideoSource? = null
    private var videoTrack: VideoTrack? = null
    private var remoteVideoTrack: VideoTrack? = null
    private var videoCapturer: VideoCapturer? = null
    private var surfaceTextureHelper: SurfaceTextureHelper? = null
    private val queuedRemoteCandidates = mutableListOf<IceCandidate>()
    private var remoteDescriptionSet = false

    init {
        PeerConnectionFactory.initialize(
            PeerConnectionFactory.InitializationOptions.builder(context)
                .setEnableInternalTracer(false)
                .createInitializationOptions()
        )
        factory = PeerConnectionFactory.builder()
            .setVideoEncoderFactory(DefaultVideoEncoderFactory(eglBase.eglBaseContext, true, true))
            .setVideoDecoderFactory(DefaultVideoDecoderFactory(eglBase.eglBaseContext))
            .createPeerConnectionFactory()

        scope.launch {
            chatRepository.callEvents.collect { event -> handleSignal(event) }
        }
    }

    fun startCall(conversation: Conversation, video: Boolean) {
        val me = authRepository.currentUser.value ?: return
        val peer = conversation.members.firstOrNull { it.id != me.id } ?: run {
            _state.value = CallUiState(phase = CallPhase.ERROR, error = "Calls require another member")
            return
        }
        if (conversation.members.size != 2) {
            _state.value = CallUiState(
                phase = CallPhase.ERROR,
                conversationId = conversation.id,
                error = "Group calling requires an SFU and is not enabled in this build"
            )
            return
        }
        val callId = UUID.randomUUID().toString()
        _state.value = CallUiState(
            phase = CallPhase.CONNECTING,
            callId = callId,
            conversationId = conversation.id,
            peerUserId = peer.id,
            peerName = peer.displayName,
            video = video,
            outgoing = true,
            speakerEnabled = video
        )
        configureAudio(video)
        scope.launch {
            runCatching {
                createPeerConnection(video)
                createOffer()
            }.onFailure(::failCall)
        }
    }

    fun acceptIncoming() {
        val current = _state.value
        if (current.phase != CallPhase.INCOMING || current.callId == null) return
        _state.value = current.copy(phase = CallPhase.CONNECTING)
        configureAudio(current.video)
        scope.launch {
            runCatching {
                createPeerConnection(current.video)
                val offer = pendingOffer ?: error("Incoming offer is missing")
                setRemoteDescription(offer) {
                    createAnswer()
                }
            }.onFailure(::failCall)
        }
    }

    fun rejectIncoming() {
        val current = _state.value
        sendSimpleSignal("call.reject", current)
        closeCall(notifyPeer = false)
    }

    fun endCall() {
        closeCall(notifyPeer = true)
    }

    fun toggleMute() {
        val next = !_state.value.muted
        audioTrack?.setEnabled(!next)
        _state.value = _state.value.copy(muted = next)
    }

    fun toggleCamera() {
        if (!_state.value.video) return
        val next = !_state.value.cameraEnabled
        videoTrack?.setEnabled(next)
        _state.value = _state.value.copy(cameraEnabled = next)
    }

    fun toggleSpeaker() {
        val next = !_state.value.speakerEnabled
        audioManager.isSpeakerphoneOn = next
        _state.value = _state.value.copy(speakerEnabled = next)
    }

    fun attachLocalRenderer(renderer: SurfaceViewRenderer) {
        renderer.init(eglBase.eglBaseContext, null)
        renderer.setMirror(true)
        renderer.setEnableHardwareScaler(true)
        videoTrack?.addSink(renderer)
    }

    fun detachLocalRenderer(renderer: SurfaceViewRenderer) {
        videoTrack?.removeSink(renderer)
        runCatching { renderer.release() }
    }

    fun attachRemoteRenderer(renderer: SurfaceViewRenderer) {
        renderer.init(eglBase.eglBaseContext, null)
        renderer.setMirror(false)
        renderer.setEnableHardwareScaler(true)
        remoteVideoTrack?.addSink(renderer)
    }

    fun detachRemoteRenderer(renderer: SurfaceViewRenderer) {
        remoteVideoTrack?.removeSink(renderer)
        runCatching { renderer.release() }
    }

    fun dispose() {
        closeCall(notifyPeer = false)
        factory.dispose()
        eglBase.release()
    }

    private var pendingOffer: SessionDescription? = null

    private fun handleSignal(event: CallSignalEvent) {
        val me = authRepository.currentUser.value ?: return
        when (event.type) {
            "call.offer" -> {
                if (_state.value.phase != CallPhase.IDLE && _state.value.phase != CallPhase.ENDED) {
                    chatRepository.sendCallSignal(
                        event.copy(type = "call.reject", targetUserId = event.fromUserId)
                    )
                    return
                }
                val peerName = chatRepository.conversations.value
                    .firstOrNull { it.id == event.conversationId }
                    ?.members
                    ?.firstOrNull { it.id == event.fromUserId }
                    ?.displayName
                    ?: "ChatNU user"
                pendingOffer = event.sdp?.let { SessionDescription(SessionDescription.Type.OFFER, it) }
                _state.value = CallUiState(
                    phase = CallPhase.INCOMING,
                    callId = event.callId,
                    conversationId = event.conversationId,
                    peerUserId = event.fromUserId,
                    peerName = peerName,
                    video = event.video,
                    outgoing = false,
                    speakerEnabled = event.video
                )
            }

            "call.answer" -> {
                if (event.callId != _state.value.callId || ! _state.value.outgoing) return
                val answer = event.sdp ?: return
                setRemoteDescription(SessionDescription(SessionDescription.Type.ANSWER, answer)) {
                    _state.value = _state.value.copy(phase = CallPhase.ACTIVE)
                }
            }

            "call.ice" -> {
                if (event.callId != _state.value.callId) return
                val candidate = event.candidate ?: return
                val ice = IceCandidate(event.sdpMid, event.sdpMLineIndex ?: 0, candidate)
                if (remoteDescriptionSet) peerConnection?.addIceCandidate(ice)
                else queuedRemoteCandidates += ice
            }

            "call.end", "call.reject" -> {
                if (event.callId == _state.value.callId) closeCall(notifyPeer = false)
            }
        }
    }

    private suspend fun createPeerConnection(video: Boolean) {
        cleanupPeerConnectionOnly()
        val config = chatRepository.rtcConfig()
        val iceServers = config.iceServers.flatMap { server ->
            server.urls.map { url ->
                PeerConnection.IceServer.builder(url)
                    .setUsername(server.username.orEmpty())
                    .setPassword(server.credential.orEmpty())
                    .createIceServer()
            }
        }
        val rtcConfig = PeerConnection.RTCConfiguration(iceServers).apply {
            sdpSemantics = PeerConnection.SdpSemantics.UNIFIED_PLAN
            continualGatheringPolicy = PeerConnection.ContinualGatheringPolicy.GATHER_CONTINUALLY
            tcpCandidatePolicy = PeerConnection.TcpCandidatePolicy.ENABLED
        }
        peerConnection = factory.createPeerConnection(rtcConfig, peerObserver)
            ?: error("Could not create WebRTC peer connection")

        audioSource = factory.createAudioSource(MediaConstraints())
        audioTrack = factory.createAudioTrack("chatnu-audio", audioSource).also {
            peerConnection?.addTrack(it, listOf("chatnu"))
        }

        if (video) {
            videoCapturer = createCameraCapturer() ?: error("No usable camera is available")
            videoSource = factory.createVideoSource(false)
            surfaceTextureHelper = SurfaceTextureHelper.create("ChatNUCamera", eglBase.eglBaseContext)
            videoCapturer?.initialize(surfaceTextureHelper, context, videoSource?.capturerObserver)
            videoCapturer?.startCapture(1280, 720, 30)
            videoTrack = factory.createVideoTrack("chatnu-video", videoSource).also {
                peerConnection?.addTrack(it, listOf("chatnu"))
            }
        }
    }

    private fun createOffer() {
        peerConnection?.createOffer(object : SimpleSdpObserver() {
            override fun onCreateSuccess(description: SessionDescription?) {
                val offer = description ?: return failCall(IllegalStateException("Offer creation returned null"))
                peerConnection?.setLocalDescription(object : SimpleSdpObserver() {
                    override fun onSetSuccess() {
                        val current = _state.value
                        val target = current.peerUserId ?: return
                        chatRepository.sendCallSignal(
                            CallSignalEvent(
                                type = "call.offer",
                                callId = current.callId ?: return,
                                conversationId = current.conversationId ?: return,
                                targetUserId = target,
                                sdp = offer.description,
                                video = current.video
                            )
                        )
                    }

                    override fun onSetFailure(error: String?) {
                        failCall(IllegalStateException(error ?: "Could not set local offer"))
                    }
                }, offer)
            }

            override fun onCreateFailure(error: String?) {
                failCall(IllegalStateException(error ?: "Could not create offer"))
            }
        }, MediaConstraints())
    }

    private fun createAnswer() {
        peerConnection?.createAnswer(object : SimpleSdpObserver() {
            override fun onCreateSuccess(description: SessionDescription?) {
                val answer = description ?: return failCall(IllegalStateException("Answer creation returned null"))
                peerConnection?.setLocalDescription(object : SimpleSdpObserver() {
                    override fun onSetSuccess() {
                        val current = _state.value
                        val target = current.peerUserId ?: return
                        chatRepository.sendCallSignal(
                            CallSignalEvent(
                                type = "call.answer",
                                callId = current.callId ?: return,
                                conversationId = current.conversationId ?: return,
                                targetUserId = target,
                                sdp = answer.description,
                                video = current.video
                            )
                        )
                        _state.value = current.copy(phase = CallPhase.ACTIVE)
                    }

                    override fun onSetFailure(error: String?) {
                        failCall(IllegalStateException(error ?: "Could not set local answer"))
                    }
                }, answer)
            }

            override fun onCreateFailure(error: String?) {
                failCall(IllegalStateException(error ?: "Could not create answer"))
            }
        }, MediaConstraints())
    }

    private fun setRemoteDescription(description: SessionDescription, onSuccess: () -> Unit) {
        peerConnection?.setRemoteDescription(object : SimpleSdpObserver() {
            override fun onSetSuccess() {
                remoteDescriptionSet = true
                queuedRemoteCandidates.forEach { peerConnection?.addIceCandidate(it) }
                queuedRemoteCandidates.clear()
                onSuccess()
            }

            override fun onSetFailure(error: String?) {
                failCall(IllegalStateException(error ?: "Could not set remote description"))
            }
        }, description)
    }

    private val peerObserver = object : PeerConnection.Observer {
        override fun onSignalingChange(newState: PeerConnection.SignalingState?) = Unit
        override fun onIceConnectionChange(newState: PeerConnection.IceConnectionState?) {
            when (newState) {
                PeerConnection.IceConnectionState.CONNECTED,
                PeerConnection.IceConnectionState.COMPLETED -> {
                    _state.value = _state.value.copy(phase = CallPhase.ACTIVE)
                }
                PeerConnection.IceConnectionState.FAILED -> failCall(IllegalStateException("WebRTC ICE connection failed"))
                else -> Unit
            }
        }
        override fun onIceConnectionReceivingChange(receiving: Boolean) = Unit
        override fun onIceGatheringChange(newState: PeerConnection.IceGatheringState?) = Unit
        override fun onIceCandidate(candidate: IceCandidate?) {
            val ice = candidate ?: return
            val current = _state.value
            val target = current.peerUserId ?: return
            chatRepository.sendCallSignal(
                CallSignalEvent(
                    type = "call.ice",
                    callId = current.callId ?: return,
                    conversationId = current.conversationId ?: return,
                    targetUserId = target,
                    candidate = ice.sdp,
                    sdpMid = ice.sdpMid,
                    sdpMLineIndex = ice.sdpMLineIndex,
                    video = current.video
                )
            )
        }
        override fun onIceCandidatesRemoved(candidates: Array<out IceCandidate>?) = Unit
        override fun onAddStream(stream: MediaStream?) = Unit
        override fun onRemoveStream(stream: MediaStream?) = Unit
        override fun onDataChannel(dataChannel: DataChannel?) = Unit
        override fun onRenegotiationNeeded() = Unit
        override fun onAddTrack(receiver: RtpReceiver?, mediaStreams: Array<out MediaStream>?) {
            val track = receiver?.track() as? VideoTrack ?: return
            remoteVideoTrack = track
        }
    }

    private fun createCameraCapturer(): VideoCapturer? {
        val enumerator: CameraEnumerator = Camera2Enumerator(context)
        val names = enumerator.deviceNames
        val front = names.firstOrNull { enumerator.isFrontFacing(it) }
        val preferred = listOfNotNull(front) + names.filterNot { it == front }
        for (name in preferred) {
            enumerator.createCapturer(name, null)?.let { return it }
        }
        return null
    }

    private fun sendSimpleSignal(type: String, current: CallUiState) {
        val target = current.peerUserId ?: return
        val callId = current.callId ?: return
        val conversationId = current.conversationId ?: return
        chatRepository.sendCallSignal(
            CallSignalEvent(
                type = type,
                callId = callId,
                conversationId = conversationId,
                targetUserId = target,
                video = current.video
            )
        )
    }

    private fun closeCall(notifyPeer: Boolean) {
        val current = _state.value
        if (notifyPeer) sendSimpleSignal("call.end", current)
        cleanupPeerConnectionOnly()
        pendingOffer = null
        audioManager.mode = AudioManager.MODE_NORMAL
        audioManager.isSpeakerphoneOn = false
        _state.value = CallUiState(phase = CallPhase.IDLE)
    }

    private fun cleanupPeerConnectionOnly() {
        runCatching { videoCapturer?.stopCapture() }
        videoCapturer?.dispose()
        videoCapturer = null
        surfaceTextureHelper?.dispose()
        surfaceTextureHelper = null
        remoteVideoTrack = null
        videoTrack?.dispose()
        videoTrack = null
        videoSource?.dispose()
        videoSource = null
        audioTrack?.dispose()
        audioTrack = null
        audioSource?.dispose()
        audioSource = null
        peerConnection?.close()
        peerConnection?.dispose()
        peerConnection = null
        remoteDescriptionSet = false
        queuedRemoteCandidates.clear()
    }

    private fun configureAudio(video: Boolean) {
        audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
        audioManager.isSpeakerphoneOn = video
    }

    private fun failCall(error: Throwable) {
        cleanupPeerConnectionOnly()
        _state.value = _state.value.copy(
            phase = CallPhase.ERROR,
            error = error.message ?: "Call failed"
        )
    }
}

private open class SimpleSdpObserver : SdpObserver {
    override fun onCreateSuccess(description: SessionDescription?) = Unit
    override fun onSetSuccess() = Unit
    override fun onCreateFailure(error: String?) = Unit
    override fun onSetFailure(error: String?) = Unit
}
