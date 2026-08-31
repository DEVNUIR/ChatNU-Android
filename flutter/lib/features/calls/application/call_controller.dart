import 'dart:async';
import 'dart:math';

import 'package:chatnu/core/di/app_providers.dart';
import 'package:chatnu/core/network/api_models.dart';
import 'package:chatnu/features/auth/application/session_controller.dart';
import 'package:chatnu/features/calls/application/call_connection_policy.dart';
import 'package:chatnu/features/conversations/domain/conversation.dart';
import 'package:chatnu/features/home/data/messenger_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

enum ChatNuCallStatus {
  idle,
  outgoing,
  ringing,
  incoming,
  connecting,
  connected,
  reconnecting,
  ended,
  failed,
}

class ChatNuCallState {
  const ChatNuCallState({
    this.status = ChatNuCallStatus.idle,
    this.callId,
    this.conversationId,
    this.peerUserId,
    this.peerName,
    this.video = false,
    this.muted = false,
    this.cameraEnabled = true,
    this.speakerOn = false,
    this.localStream,
    this.remoteStream,
    this.error,
  });

  final ChatNuCallStatus status;
  final String? callId;
  final String? conversationId;
  final String? peerUserId;
  final String? peerName;
  final bool video;
  final bool muted;
  final bool cameraEnabled;
  final bool speakerOn;
  final MediaStream? localStream;
  final MediaStream? remoteStream;
  final String? error;

  bool get active =>
      status != ChatNuCallStatus.idle && status != ChatNuCallStatus.ended;

  ChatNuCallState copyWith({
    ChatNuCallStatus? status,
    String? callId,
    String? conversationId,
    String? peerUserId,
    String? peerName,
    bool? video,
    bool? muted,
    bool? cameraEnabled,
    bool? speakerOn,
    MediaStream? localStream,
    MediaStream? remoteStream,
    String? error,
    bool clearError = false,
  }) {
    return ChatNuCallState(
      status: status ?? this.status,
      callId: callId ?? this.callId,
      conversationId: conversationId ?? this.conversationId,
      peerUserId: peerUserId ?? this.peerUserId,
      peerName: peerName ?? this.peerName,
      video: video ?? this.video,
      muted: muted ?? this.muted,
      cameraEnabled: cameraEnabled ?? this.cameraEnabled,
      speakerOn: speakerOn ?? this.speakerOn,
      localStream: localStream ?? this.localStream,
      remoteStream: remoteStream ?? this.remoteStream,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class CallController extends Notifier<ChatNuCallState> {
  MessengerRepository? _repository;
  StreamSubscription<Map<String, dynamic>>? _events;
  RTCPeerConnection? _peer;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  Map<String, dynamic>? _pendingOffer;
  Timer? _disconnectGraceTimer;
  Timer? _ringingTimer;
  bool _attached = false;

  @override
  ChatNuCallState build() {
    final mode = ref.watch(appModeProvider);
    final session = ref.watch(sessionProvider);
    if (mode == ChatNuAppMode.production &&
        session.isAuthenticated &&
        !_attached) {
      _attached = true;
      Future<void>.microtask(_attachRealtime);
    }
    ref.onDispose(() {
      _disconnectGraceTimer?.cancel();
      _ringingTimer?.cancel();
      unawaited(_events?.cancel());
      unawaited(_disposePeer());
    });
    return const ChatNuCallState();
  }

  Future<void> _attachRealtime() async {
    final repository = ref.read(messengerRepositoryProvider);
    _repository = repository;
    _events = repository.realtime.events.listen(_handleSignal);
    await repository.startRealtime();
    try {
      final pending = await repository.pendingCalls();
      if (pending.isNotEmpty && !state.active) {
        _offerFromPending(pending.first);
      }
    } catch (_) {
      // Realtime offers remain available even when pending-call recovery fails.
    }
  }

  Future<void> startCall({
    required ChatNuConversation conversation,
    required String currentUserId,
    required bool video,
  }) async {
    if (conversation.kind != ConversationKind.direct || state.active) return;
    final peer = conversation.members
        .where((member) => member.id != currentUserId)
        .firstOrNull;
    if (peer == null) return;
    final MessengerRepository repository =
        _repository ?? ref.read(messengerRepositoryProvider);
    _repository = repository;
    try {
      final callId = _newCallId();
      state = ChatNuCallState(
        status: ChatNuCallStatus.outgoing,
        callId: callId,
        conversationId: conversation.id,
        peerUserId: peer.id,
        peerName: peer.displayName,
        video: video,
        cameraEnabled: video,
      );
      await _preparePeer(video: video);
      final offer = await _peer!.createOffer(<String, dynamic>{});
      await _peer!.setLocalDescription(offer);
      final sent = repository.realtime.send(<String, dynamic>{
        'type': 'call.offer',
        'callId': callId,
        'conversationId': conversation.id,
        'targetUserId': peer.id,
        'sdp': offer.sdp,
        'video': video,
      });
      if (!sent) throw StateError('Realtime connection is not available.');
      state = state.copyWith(
        status: ChatNuCallStatus.ringing,
        clearError: true,
      );
      _startRingingTimeout();
    } catch (error) {
      await _fail(error);
    }
  }

  Future<void> accept() async {
    final offer = _pendingOffer;
    if (offer == null || state.status != ChatNuCallStatus.incoming) return;
    try {
      state = state.copyWith(
        status: ChatNuCallStatus.connecting,
        clearError: true,
      );
      await _preparePeer(video: state.video);
      await _peer!.setRemoteDescription(
        RTCSessionDescription(offer['sdp']?.toString(), 'offer'),
      );
      final answer = await _peer!.createAnswer(<String, dynamic>{});
      await _peer!.setLocalDescription(answer);
      final sent = _repository!.realtime.send(<String, dynamic>{
        'type': 'call.answer',
        'callId': state.callId,
        'conversationId': state.conversationId,
        'targetUserId': state.peerUserId,
        'sdp': answer.sdp,
        'video': state.video,
      });
      if (!sent) throw StateError('Realtime connection is not available.');
      _pendingOffer = null;
    } catch (error) {
      await _fail(error);
    }
  }

  Future<void> reject() async {
    if (!state.active) return;
    _repository?.realtime.send(<String, dynamic>{
      'type': 'call.reject',
      'callId': state.callId,
      'conversationId': state.conversationId,
      'targetUserId': state.peerUserId,
    });
    await _endLocal();
  }

  Future<void> end() async {
    if (!state.active) return;
    _repository?.realtime.send(<String, dynamic>{
      'type': 'call.end',
      'callId': state.callId,
      'conversationId': state.conversationId,
      'targetUserId': state.peerUserId,
    });
    await _endLocal();
  }

  void toggleMute() {
    final next = !state.muted;
    for (final track
        in _localStream?.getAudioTracks() ?? <MediaStreamTrack>[]) {
      track.enabled = !next;
    }
    state = state.copyWith(muted: next, clearError: true);
  }

  void toggleCamera() {
    if (!state.video) return;
    final next = !state.cameraEnabled;
    for (final track
        in _localStream?.getVideoTracks() ?? <MediaStreamTrack>[]) {
      track.enabled = next;
    }
    state = state.copyWith(cameraEnabled: next, clearError: true);
  }

  Future<void> toggleSpeaker() async {
    final next = !state.speakerOn;
    try {
      await Helper.setSpeakerphoneOn(next);
      state = state.copyWith(speakerOn: next, clearError: true);
    } catch (_) {
      state = state.copyWith(error: 'Couldn’t change speaker output.');
    }
  }

  Future<void> switchCamera() async {
    if (!state.video) return;
    final tracks = _localStream?.getVideoTracks() ?? <MediaStreamTrack>[];
    if (tracks.isEmpty) return;
    try {
      await Helper.switchCamera(tracks.first, null, _localStream);
      state = state.copyWith(clearError: true);
    } catch (_) {
      state = state.copyWith(error: 'Couldn’t switch cameras.');
    }
  }

  Future<void> _preparePeer({required bool video}) async {
    final MessengerRepository repository =
        _repository ?? ref.read(messengerRepositoryProvider);
    _repository = repository;
    final config = await repository.rtcConfig();
    final iceServers = config.iceServers
        .map(
          (server) => <String, dynamic>{
            'urls': server.urls,
            if (server.username != null) 'username': server.username,
            if (server.credential != null) 'credential': server.credential,
          },
        )
        .toList(growable: false);
    final peer = await createPeerConnection(<String, dynamic>{
      'iceServers': iceServers,
      'sdpSemantics': 'unified-plan',
    });
    _peer = peer;
    peer.onIceCandidate = (candidate) {
      if (candidate.candidate == null) return;
      _repository?.realtime.send(<String, dynamic>{
        'type': 'call.ice',
        'callId': state.callId,
        'conversationId': state.conversationId,
        'targetUserId': state.peerUserId,
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    };
    peer.onTrack = (event) {
      if (event.streams.isEmpty) return;
      _remoteStream = event.streams.first;
      state = state.copyWith(remoteStream: _remoteStream);
    };
    peer.onConnectionState = _handlePeerConnectionState;

    final stream = await navigator.mediaDevices.getUserMedia(<String, dynamic>{
      'audio': true,
      'video': video ? <String, dynamic>{'facingMode': 'user'} : false,
    });
    _localStream = stream;
    for (final track in stream.getTracks()) {
      await peer.addTrack(track, stream);
    }
    state = state.copyWith(localStream: stream);
  }

  void _handlePeerConnectionState(RTCPeerConnectionState connectionState) {
    if (connectionState ==
        RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
      _disconnectGraceTimer?.cancel();
      _disconnectGraceTimer = null;
      _ringingTimer?.cancel();
      _ringingTimer = null;
      state = state.copyWith(
        status: ChatNuCallStatus.connected,
        clearError: true,
      );
      return;
    }

    if (connectionState ==
        RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
      if (state.status == ChatNuCallStatus.connected ||
          state.status == ChatNuCallStatus.connecting ||
          state.status == ChatNuCallStatus.reconnecting) {
        state = state.copyWith(
          status: ChatNuCallStatus.reconnecting,
          clearError: true,
        );
        _startDisconnectGrace();
      }
      return;
    }

    if (connectionState ==
        RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
      unawaited(_fail(StateError('Call connection failed.')));
    }
  }

  void _startDisconnectGrace() {
    _disconnectGraceTimer?.cancel();
    _disconnectGraceTimer = Timer(
      ChatNuCallConnectionPolicy.disconnectGrace,
      () {
        if (state.status != ChatNuCallStatus.reconnecting) return;
        unawaited(_failFriendly('Call connection was lost.'));
      },
    );
  }

  void _startRingingTimeout() {
    _ringingTimer?.cancel();
    _ringingTimer = Timer(ChatNuCallConnectionPolicy.ringingTimeout, () {
      if (state.status != ChatNuCallStatus.ringing) return;
      unawaited(_failFriendly('No answer.'));
    });
  }

  void _handleSignal(Map<String, dynamic> event) {
    final type = event['type']?.toString();
    if (type == null || !type.startsWith('call.')) return;
    if (type == 'call.offer') {
      if (!state.active) _offerFromMap(event);
      return;
    }
    if (event['callId']?.toString() != state.callId) return;
    switch (type) {
      case 'call.answer':
        unawaited(_applyAnswer(event));
      case 'call.ice':
        unawaited(_applyIce(event));
      case 'call.reject':
      case 'call.end':
        unawaited(_endLocal());
    }
  }

  Future<void> _applyAnswer(Map<String, dynamic> event) async {
    final sdp = event['sdp']?.toString();
    if (sdp == null || _peer == null) return;
    _ringingTimer?.cancel();
    _ringingTimer = null;
    await _peer!.setRemoteDescription(RTCSessionDescription(sdp, 'answer'));
    state = state.copyWith(
      status: ChatNuCallStatus.connecting,
      clearError: true,
    );
  }

  Future<void> _applyIce(Map<String, dynamic> event) async {
    final candidate = event['candidate']?.toString();
    if (candidate == null || _peer == null) return;
    final rawIndex = event['sdpMLineIndex'];
    final index = rawIndex is num
        ? rawIndex.toInt()
        : int.tryParse('$rawIndex');
    await _peer!.addCandidate(
      RTCIceCandidate(candidate, event['sdpMid']?.toString(), index),
    );
  }

  void _offerFromMap(Map<String, dynamic> event) {
    final callId = event['callId']?.toString();
    final conversationId = event['conversationId']?.toString();
    final fromUserId = event['fromUserId']?.toString();
    final sdp = event['sdp']?.toString();
    if (callId == null ||
        conversationId == null ||
        fromUserId == null ||
        sdp == null) {
      return;
    }
    _pendingOffer = event;
    state = ChatNuCallState(
      status: ChatNuCallStatus.incoming,
      callId: callId,
      conversationId: conversationId,
      peerUserId: fromUserId,
      peerName: event['fromDisplayName']?.toString() ?? 'ChatNU contact',
      video: event['video'] == true,
      cameraEnabled: event['video'] == true,
    );
  }

  void _offerFromPending(PendingCallDto call) {
    _offerFromMap(<String, dynamic>{
      'type': call.type,
      'callId': call.callId,
      'conversationId': call.conversationId,
      'targetUserId': call.targetUserId,
      'fromUserId': call.fromUserId,
      'fromDeviceId': call.fromDeviceId,
      'sdp': call.sdp,
      'video': call.video,
      'sentAt': call.sentAt,
    });
  }

  Future<void> _fail(Object error) async {
    await _failFriendly(
      ChatNuCallConnectionPolicy.friendlyError(error, video: state.video),
    );
  }

  Future<void> _failFriendly(String message) async {
    final previous = state;
    await _disposePeer();
    state = ChatNuCallState(
      status: ChatNuCallStatus.failed,
      callId: previous.callId,
      conversationId: previous.conversationId,
      peerUserId: previous.peerUserId,
      peerName: previous.peerName,
      video: previous.video,
      error: message,
    );
  }

  Future<void> _endLocal() async {
    await _disposePeer();
    _pendingOffer = null;
    state = const ChatNuCallState(status: ChatNuCallStatus.ended);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    state = const ChatNuCallState();
  }

  Future<void> _disposePeer() async {
    _disconnectGraceTimer?.cancel();
    _disconnectGraceTimer = null;
    _ringingTimer?.cancel();
    _ringingTimer = null;
    try {
      await Helper.setSpeakerphoneOn(false);
      await Helper.clearAndroidCommunicationDevice();
    } catch (_) {}
    final peer = _peer;
    _peer = null;
    if (peer != null) await peer.close();
    final local = _localStream;
    _localStream = null;
    for (final track in local?.getTracks() ?? <MediaStreamTrack>[]) {
      await track.stop();
    }
    final remote = _remoteStream;
    _remoteStream = null;
    for (final track in remote?.getTracks() ?? <MediaStreamTrack>[]) {
      await track.stop();
    }
  }

  String _newCallId() {
    final random = Random.secure();
    return 'call-${DateTime.now().microsecondsSinceEpoch}-${random.nextInt(1 << 31)}';
  }
}

final callControllerProvider =
    NotifierProvider<CallController, ChatNuCallState>(CallController.new);

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
