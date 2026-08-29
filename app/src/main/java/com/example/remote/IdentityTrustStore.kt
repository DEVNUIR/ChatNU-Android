package com.example.remote

import android.content.Context
import java.security.MessageDigest

data class ConversationSecuritySummary(
    val safetyNumber: String,
    val verified: Boolean,
    val identityChanged: Boolean,
    val deviceCount: Int
)

/**
 * Pins the complete active-device identity set for a conversation after explicit user verification.
 * Public identity keys/fingerprints are not secret, so ordinary app-private SharedPreferences are
 * sufficient storage. A compromised endpoint is outside this protection boundary.
 */
class IdentityTrustStore(context: Context) {
    private val prefs = context.getSharedPreferences("chatnu_identity_trust", Context.MODE_PRIVATE)

    fun inspect(conversationId: String, devices: List<DeviceKeyDto>): ConversationSecuritySummary {
        val current = digestDeviceSet(devices)
        val key = verifiedKey(conversationId)
        val verifiedDigest = prefs.getString(key, null)
        return ConversationSecuritySummary(
            safetyNumber = displaySafetyNumber(current),
            verified = verifiedDigest != null && verifiedDigest == current,
            identityChanged = verifiedDigest != null && verifiedDigest != current,
            deviceCount = devices.size
        )
    }

    fun verify(conversationId: String, devices: List<DeviceKeyDto>): ConversationSecuritySummary {
        val current = digestDeviceSet(devices)
        prefs.edit().putString(verifiedKey(conversationId), current).apply()
        return ConversationSecuritySummary(
            safetyNumber = displaySafetyNumber(current),
            verified = true,
            identityChanged = false,
            deviceCount = devices.size
        )
    }

    fun clear(conversationId: String) {
        prefs.edit().remove(verifiedKey(conversationId)).apply()
    }

    private fun verifiedKey(conversationId: String): String {
        val namespace = ServerEndpoint.identityNamespace()
        val raw = "$namespace|$conversationId"
        val digest = MessageDigest.getInstance("SHA-256")
            .digest(raw.toByteArray(Charsets.UTF_8))
            .joinToString("") { "%02x".format(it) }
        return "verified_$digest"
    }

    private fun digestDeviceSet(devices: List<DeviceKeyDto>): String {
        require(devices.isNotEmpty()) { "No device identity keys are available" }
        val canonical = devices
            .sortedWith(compareBy<DeviceKeyDto> { it.userId }.thenBy { it.deviceId })
            .joinToString("\n") { "${it.userId}|${it.deviceId}|${it.publicKey.trim()}" }
        return MessageDigest.getInstance("SHA-256")
            .digest(canonical.toByteArray(Charsets.UTF_8))
            .joinToString("") { "%02X".format(it) }
    }

    private fun displaySafetyNumber(hexDigest: String): String = hexDigest
        .chunked(4)
        .joinToString(" ")
}
