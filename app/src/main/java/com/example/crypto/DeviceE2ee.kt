package com.example.crypto

import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import java.security.KeyFactory
import java.security.KeyPair
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.MessageDigest
import java.security.spec.MGF1ParameterSpec
import java.security.spec.X509EncodedKeySpec
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.OAEPParameterSpec
import javax.crypto.spec.PSource
import javax.crypto.spec.SecretKeySpec

data class RecipientDeviceKey(
    val deviceId: String,
    val publicKeyBase64: String
)

data class E2eeEnvelope(
    val ciphertextBase64: String,
    val nonceBase64: String,
    val wrappedKeys: Map<String, String>,
    val protocolVersion: String = DeviceE2ee.PROTOCOL_VERSION
)

data class EncryptedAttachment(
    val ciphertext: ByteArray,
    val keyBase64: String,
    val nonceBase64: String
)

/**
 * ChatNU's production E2EE envelope.
 *
 * Each message uses a fresh AES-256-GCM content key. That content key is wrapped independently
 * for every active recipient device with that device's RSA-3072 OAEP public key. Private identity
 * keys are generated inside Android Keystore and never uploaded.
 *
 * This is real end-to-end encryption, but it is deliberately not described as Signal/Double
 * Ratchet: version 1 does not provide Signal-style per-message forward secrecy or deniability.
 */
class DeviceE2ee {
    fun publicKeyBase64(account: String): String {
        val pair = getOrCreateIdentity(account)
        return encode(pair.public.encoded)
    }

    fun encryptMessage(
        plaintext: ByteArray,
        recipientKeys: List<RecipientDeviceKey>,
        aad: String
    ): E2eeEnvelope {
        require(recipientKeys.isNotEmpty()) { "No recipient device keys are available" }
        val contentKey = randomAesKey()
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, contentKey)
        cipher.updateAAD(aad.toByteArray(Charsets.UTF_8))
        val ciphertext = cipher.doFinal(plaintext)

        val wrapped = linkedMapOf<String, String>()
        recipientKeys.distinctBy { it.deviceId }.forEach { recipient ->
            val remotePublicKey = KeyFactory.getInstance("RSA").generatePublic(
                X509EncodedKeySpec(decode(recipient.publicKeyBase64))
            )
            val wrapper = rsaOaepCipher()
            wrapper.init(Cipher.ENCRYPT_MODE, remotePublicKey, OAEP_SHA256_MGF1_SHA1)
            wrapped[recipient.deviceId] = encode(wrapper.doFinal(contentKey.encoded))
        }

        return E2eeEnvelope(
            ciphertextBase64 = encode(ciphertext),
            nonceBase64 = encode(cipher.iv),
            wrappedKeys = wrapped
        )
    }

    fun decryptMessage(
        account: String,
        deviceId: String,
        ciphertextBase64: String,
        nonceBase64: String,
        metadata: Map<String, Any?>?,
        aad: String
    ): ByteArray {
        val wrappedMap = metadata?.get("wrappedKeys") as? Map<*, *>
            ?: error("Encrypted message is missing wrappedKeys")
        val wrappedKey = wrappedMap.entries
            .firstOrNull { it.key?.toString() == deviceId }
            ?.value
            ?.toString()
            ?: error("This message was not encrypted for the current device")

        val privateKey = getOrCreateIdentity(account).private
        val unwrapper = rsaOaepCipher()
        unwrapper.init(Cipher.DECRYPT_MODE, privateKey, OAEP_SHA256_MGF1_SHA1)
        val contentKey = SecretKeySpec(unwrapper.doFinal(decode(wrappedKey)), "AES")

        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(
            Cipher.DECRYPT_MODE,
            contentKey,
            GCMParameterSpec(128, decode(nonceBase64))
        )
        cipher.updateAAD(aad.toByteArray(Charsets.UTF_8))
        return cipher.doFinal(decode(ciphertextBase64))
    }

    fun encryptAttachment(plaintext: ByteArray): EncryptedAttachment {
        val key = randomAesKey()
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, key)
        return EncryptedAttachment(
            ciphertext = cipher.doFinal(plaintext),
            keyBase64 = encode(key.encoded),
            nonceBase64 = encode(cipher.iv)
        )
    }

    fun decryptAttachment(ciphertext: ByteArray, keyBase64: String, nonceBase64: String): ByteArray {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(
            Cipher.DECRYPT_MODE,
            SecretKeySpec(decode(keyBase64), "AES"),
            GCMParameterSpec(128, decode(nonceBase64))
        )
        return cipher.doFinal(ciphertext)
    }

    private fun getOrCreateIdentity(account: String): KeyPair {
        val alias = identityAlias(account)
        val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        val existingPrivate = keyStore.getKey(alias, null)
        val existingPublic = keyStore.getCertificate(alias)?.publicKey
        if (existingPrivate != null && existingPublic != null) {
            return KeyPair(existingPublic, existingPrivate as java.security.PrivateKey)
        }

        val generator = KeyPairGenerator.getInstance(KeyProperties.KEY_ALGORITHM_RSA, "AndroidKeyStore")
        generator.initialize(
            KeyGenParameterSpec.Builder(
                alias,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
            )
                .setKeySize(3072)
                .setDigests(KeyProperties.DIGEST_SHA256, KeyProperties.DIGEST_SHA1)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_RSA_OAEP)
                .build()
        )
        return generator.generateKeyPair()
    }

    private fun identityAlias(account: String): String {
        val digest = MessageDigest.getInstance("SHA-256")
            .digest(account.trim().lowercase().toByteArray(Charsets.UTF_8))
            .joinToString("") { "%02x".format(it) }
            .take(24)
        return "chatnu_e2ee_identity_$digest"
    }

    private fun randomAesKey(): SecretKey = KeyGenerator.getInstance("AES").run {
        init(256)
        generateKey()
    }

    private fun rsaOaepCipher(): Cipher = Cipher.getInstance("RSA/ECB/OAEPWithSHA-256AndMGF1Padding")

    private fun encode(bytes: ByteArray): String = Base64.encodeToString(bytes, Base64.NO_WRAP)
    private fun decode(value: String): ByteArray = Base64.decode(value, Base64.NO_WRAP)

    companion object {
        const val PROTOCOL_VERSION = "chatnu-e2ee-rsa3072-aes256gcm-v1"

        private val OAEP_SHA256_MGF1_SHA1 = OAEPParameterSpec(
            "SHA-256",
            "MGF1",
            MGF1ParameterSpec.SHA1,
            PSource.PSpecified.DEFAULT
        )
    }
}
