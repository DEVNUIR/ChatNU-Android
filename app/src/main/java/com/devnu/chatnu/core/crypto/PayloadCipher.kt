package com.devnu.chatnu.core.crypto

import android.util.Base64
import com.devnu.chatnu.BuildConfig
import java.security.SecureRandom

interface PayloadCipher {
    fun encrypt(plaintext: String): EncryptedPayload
    fun decrypt(ciphertext: String, nonce: String): String
}

data class EncryptedPayload(val ciphertext: String, val nonce: String)

class DevelopmentPayloadCipher : PayloadCipher {
    override fun encrypt(plaintext: String): EncryptedPayload {
        check(BuildConfig.ALLOW_INSECURE_DEMO_PAYLOADS) {
            "DevelopmentPayloadCipher must never be used in release builds"
        }
        val nonce = ByteArray(12).also(SecureRandom()::nextBytes)
        return EncryptedPayload(
            ciphertext = Base64.encodeToString(plaintext.toByteArray(), Base64.NO_WRAP),
            nonce = Base64.encodeToString(nonce, Base64.NO_WRAP),
        )
    }

    override fun decrypt(ciphertext: String, nonce: String): String {
        check(BuildConfig.ALLOW_INSECURE_DEMO_PAYLOADS)
        return Base64.decode(ciphertext, Base64.NO_WRAP).decodeToString()
    }
}
