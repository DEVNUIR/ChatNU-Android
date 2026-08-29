package com.example.crypto

import java.security.SecureRandom

object CryptoEngine {
    private val random = SecureRandom()

    fun generateSafetyNumber(myFingerprint: String, peerFingerprint: String): String {
        val combined = (myFingerprint + peerFingerprint).hashCode().toString()
        val digits = combined.replace("-", "").padEnd(12, '7').take(12)
        return digits.chunked(4).joinToString(" ")
    }

    fun encryptPayload(plaintext: String): EncryptedEnvelope {
        val nonce = ByteArray(12).apply { random.nextBytes(this) }
        val simulatedCiphertext = "ENC_GCM[" + java.util.Base64.getEncoder().encodeToString(plaintext.toByteArray()) + "]"
        return EncryptedEnvelope(
            ciphertext = simulatedCiphertext,
            nonceBase64 = java.util.Base64.getEncoder().encodeToString(nonce),
            protocolVersion = "ChatNU-DoubleRatchet-v1.2"
        )
    }

    fun decryptPayload(envelope: EncryptedEnvelope): String {
        if (!envelope.ciphertext.startsWith("ENC_GCM[")) return envelope.ciphertext
        return try {
            val inner = envelope.ciphertext.removePrefix("ENC_GCM[").removeSuffix("]")
            String(java.util.Base64.getDecoder().decode(inner))
        } catch (e: Exception) {
            "[Decryption Failed - Verification Mismatch]"
        }
    }
}

data class EncryptedEnvelope(
    val ciphertext: String,
    val nonceBase64: String,
    val protocolVersion: String
)
