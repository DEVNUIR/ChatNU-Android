package ir.devnu.chatnu

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.KeyPair
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.MessageDigest
import java.security.spec.MGF1ParameterSpec
import javax.crypto.Cipher
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.OAEPParameterSpec
import javax.crypto.spec.PSource

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            runCatching {
                when (call.method) {
                    "identityPublicKey" -> {
                        val account = call.argument<String>("account") ?: error("account is required")
                        Base64.encodeToString(getOrCreateIdentity(account).public.encoded, Base64.NO_WRAP)
                    }
                    "unwrapContentKey" -> {
                        val account = call.argument<String>("account") ?: error("account is required")
                        val wrapped = call.argument<String>("wrappedKey") ?: error("wrappedKey is required")
                        val cipher = Cipher.getInstance("RSA/ECB/OAEPWithSHA-256AndMGF1Padding")
                        cipher.init(
                            Cipher.DECRYPT_MODE,
                            getOrCreateIdentity(account).private,
                            OAEP_SHA256_MGF1_SHA1
                        )
                        cipher.doFinal(Base64.decode(wrapped, Base64.NO_WRAP))
                    }
                    "readLegacyState" -> readLegacyState()
                    else -> null
                }
            }.onSuccess { value ->
                if (call.method == "unwrapContentKey") result.success(value as ByteArray)
                else result.success(value)
            }.onFailure { error ->
                result.error("CHATNU_NATIVE", error.message, null)
            }
        }
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

    private fun readLegacyState(): Map<String, Any?> {
        val sessionPrefs = getSharedPreferences("chatnu_session", Context.MODE_PRIVATE)
        val serverPrefs = getSharedPreferences("chatnu_server", Context.MODE_PRIVATE)
        val session = linkedMapOf<String, Any?>()
        readLegacyEncrypted(sessionPrefs, "access_token")?.let { session["accessToken"] = it }
        readLegacyEncrypted(sessionPrefs, "refresh_token")?.let { session["refreshToken"] = it }
        readLegacyEncrypted(sessionPrefs, "device_id")?.let { session["deviceId"] = it }
        readLegacyEncrypted(sessionPrefs, "crypto_account")?.let { session["cryptoAccount"] = it }
        sessionPrefs.getString("user_id", null)?.let { session["userId"] = it }
        sessionPrefs.getString("username", null)?.let { session["username"] = it }
        sessionPrefs.getString("display_name", null)?.let { session["displayName"] = it }
        sessionPrefs.getString("avatar_url", null)?.let { session["avatarUrl"] = it }
        sessionPrefs.getString("bio", null)?.let { session["bio"] = it }

        val server = linkedMapOf<String, Any?>()
        serverPrefs.getString("api_url", null)?.let { server["apiUrl"] = it }
        serverPrefs.getString("tls_ca_pin", null)?.let { server["tlsCaPin"] = it }
        return mapOf("session" to session, "server" to server)
    }

    private fun readLegacyEncrypted(prefs: android.content.SharedPreferences, name: String): String? {
        val packed = prefs.getString(name, null) ?: return null
        return runCatching {
            val parts = packed.split(":", limit = 2)
            require(parts.size == 2)
            val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
            val key = keyStore.getKey(LEGACY_SESSION_KEY_ALIAS, null) ?: return null
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            cipher.init(
                Cipher.DECRYPT_MODE,
                key,
                GCMParameterSpec(128, Base64.decode(parts[0], Base64.NO_WRAP))
            )
            String(cipher.doFinal(Base64.decode(parts[1], Base64.NO_WRAP)), Charsets.UTF_8)
        }.getOrNull()
    }

    companion object {
        private const val CHANNEL = "ir.devnu.chatnu/native"
        private const val LEGACY_SESSION_KEY_ALIAS = "chatnu_session_aes_v1"
        private val OAEP_SHA256_MGF1_SHA1 = OAEPParameterSpec(
            "SHA-256",
            "MGF1",
            MGF1ParameterSpec.SHA1,
            PSource.PSpecified.DEFAULT
        )
    }
}
