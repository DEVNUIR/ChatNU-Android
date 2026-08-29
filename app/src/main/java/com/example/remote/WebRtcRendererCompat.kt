package com.example.remote

import org.webrtc.SurfaceViewRenderer

/**
 * Small adapter used by Compose AndroidView. AndroidView may invoke both factory and update during
 * initial composition, so the tag guard avoids initializing the same WebRTC renderer twice.
 */
fun WebRtcCallManager.attachRenderer(renderer: SurfaceViewRenderer, local: Boolean) {
    val role = if (local) "chatnu-webrtc-local" else "chatnu-webrtc-remote"
    if (renderer.tag == role) return
    renderer.tag = role
    if (local) attachLocalRenderer(renderer) else attachRemoteRenderer(renderer)
}
