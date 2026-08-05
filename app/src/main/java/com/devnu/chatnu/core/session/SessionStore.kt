package com.devnu.chatnu.core.session

import android.content.Context
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey

class SessionStore(context: Context) {
    private val masterKey = MasterKey.Builder(context)
        .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
        .build()
    private val preferences = EncryptedSharedPreferences.create(
        context,
        "chatnu_session",
        masterKey,
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM,
    )

    fun accessToken(): String? = preferences.getString("access_token", null)
    fun refreshToken(): String? = preferences.getString("refresh_token", null)
    fun syncCursor(): String? = preferences.getString("sync_cursor", null)

    fun saveTokens(accessToken: String, refreshToken: String) {
        check(preferences.edit().putString("access_token", accessToken).putString("refresh_token", refreshToken).commit())
    }

    fun saveSyncCursor(cursor: String) {
        preferences.edit().putString("sync_cursor", cursor).apply()
    }

    fun clearTokens() {
        preferences.edit().remove("access_token").remove("refresh_token").apply()
    }
}
