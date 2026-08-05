package com.devnu.chatnu.core.database

import android.content.Context
import androidx.room.Room
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import net.sqlcipher.database.SQLiteDatabase
import net.sqlcipher.database.SupportFactory
import java.security.SecureRandom

object DatabaseFactory {
    fun create(context: Context): ChatNuDatabase {
        SQLiteDatabase.loadLibs(context)
        val passphrase = SQLiteDatabase.getBytes(databaseSecret(context))
        return Room.databaseBuilder(context, ChatNuDatabase::class.java, "chatnu.db")
            .openHelperFactory(SupportFactory(passphrase))
            .fallbackToDestructiveMigrationOnDowngrade()
            .build()
    }

    private fun databaseSecret(context: Context): CharArray {
        val masterKey = MasterKey.Builder(context)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build()
        val preferences = EncryptedSharedPreferences.create(
            context,
            "chatnu_secure_storage",
            masterKey,
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM,
        )
        val existing = preferences.getString("database_passphrase", null)
        if (existing != null) return existing.toCharArray()
        val bytes = ByteArray(48).also(SecureRandom()::nextBytes)
        val generated = android.util.Base64.encodeToString(bytes, android.util.Base64.NO_WRAP)
        check(preferences.edit().putString("database_passphrase", generated).commit())
        return generated.toCharArray()
    }
}
