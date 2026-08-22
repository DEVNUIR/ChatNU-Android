package com.example.remote

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import com.example.model.User
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

class TokenStore(context: Context) {
    private val prefs = context.getSharedPreferences("chatnu_session", Context.MODE_PRIVATE)

    var accessToken: String?
        get() = readEncrypted("access_token")
        set(value) = writeEncrypted("access_token", value)

    var refreshToken: String?
        get() = readEncrypted("refresh_token")
        set(value) = writeEncrypted("refresh_token", value)

    var deviceId: String?
        get() = readEncrypted("device_id")
        set(value) = writeEncrypted("device_id", value)

    var cryptoAccount: String?
        get() = readEncrypted("crypto_account")
        set(value) = writeEncrypted("crypto_account", value?.trim()?.lowercase())

    fun saveUser(user: UserDto) {
        prefs.edit()
            .putString("user_id", user.id)
            .putString("username", user.username)
            .putString("display_name", user.displayName)
            .putString("avatar_url", user.avatarUrl)
            .putString("bio", user.bio)
            .apply()
    }

    fun loadUser(): User? {
        val id = prefs.getString("user_id", null) ?: return null
        val username = prefs.getString("username", null) ?: return null
        val displayName = prefs.getString("display_name", null) ?: username
        return User(
            id = id,
            username = username,
            displayName = displayName,
            avatarUrl = prefs.getString("avatar_url", null),
            bio = prefs.getString("bio", null)
        )
    }

    fun clear() {
        prefs.edit().clear().apply()
    }

    private fun writeEncrypted(name: String, value: String?) {
        if (value == null) {
            prefs.edit().remove(name).apply()
            return
        }
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, getOrCreateKey())
        val encrypted = cipher.doFinal(value.toByteArray(Charsets.UTF_8))
        val packed = Base64.encodeToString(cipher.iv, Base64.NO_WRAP) + ":" +
            Base64.encodeToString(encrypted, Base64.NO_WRAP)
        prefs.edit().putString(name, packed).apply()
    }

    private fun readEncrypted(name: String): String? {
        val packed = prefs.getString(name, null) ?: return null
        return runCatching {
            val parts = packed.split(":", limit = 2)
            require(parts.size == 2)
            val iv = Base64.decode(parts[0], Base64.NO_WRAP)
            val encrypted = Base64.decode(parts[1], Base64.NO_WRAP)
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            cipher.init(Cipher.DECRYPT_MODE, getOrCreateKey(), GCMParameterSpec(128, iv))
            String(cipher.doFinal(encrypted), Charsets.UTF_8)
        }.getOrElse {
            prefs.edit().remove(name).apply()
            null
        }
    }

    private fun getOrCreateKey(): SecretKey {
        val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        (keyStore.getKey(KEY_ALIAS, null) as? SecretKey)?.let { return it }
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
        generator.init(
            KeyGenParameterSpec.Builder(
                KEY_ALIAS,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .build()
        )
        return generator.generateKey()
    }

    companion object {
        private const val KEY_ALIAS = "chatnu_session_aes_v1"
    }
}
