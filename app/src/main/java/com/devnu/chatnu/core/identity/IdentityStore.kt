package com.devnu.chatnu.core.identity

import android.content.Context
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.devnu.chatnu.core.model.LocalIdentity
import java.security.KeyPairGenerator
import java.security.MessageDigest
import java.util.UUID
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

private val Context.identityDataStore by preferencesDataStore("identity")

class IdentityStore(private val context: Context) {
    private object Keys {
        val userId = stringPreferencesKey("user_id")
        val username = stringPreferencesKey("username")
        val displayName = stringPreferencesKey("display_name")
        val deviceId = stringPreferencesKey("device_id")
        val publicKey = stringPreferencesKey("public_identity_key")
        val fingerprint = stringPreferencesKey("fingerprint")
        val recoveryCreated = booleanPreferencesKey("recovery_created")
        val onboardingComplete = booleanPreferencesKey("onboarding_complete")
    }

    val identity: Flow<LocalIdentity?> = context.identityDataStore.data.map { p ->
        val userId = p[Keys.userId] ?: return@map null
        LocalIdentity(
            userId = userId,
            username = p[Keys.username].orEmpty(),
            displayName = p[Keys.displayName].orEmpty(),
            deviceId = p[Keys.deviceId].orEmpty(),
            publicIdentityKey = p[Keys.publicKey].orEmpty(),
            fingerprint = p[Keys.fingerprint].orEmpty(),
            recoveryCreated = p[Keys.recoveryCreated] ?: false,
        )
    }

    val onboardingComplete: Flow<Boolean> = context.identityDataStore.data.map { it[Keys.onboardingComplete] ?: false }

    suspend fun createIdentity(username: String, displayName: String): LocalIdentity {
        val keyPair = KeyPairGenerator.getInstance("EC").apply { initialize(256) }.generateKeyPair()
        val publicKey = android.util.Base64.encodeToString(keyPair.public.encoded, android.util.Base64.NO_WRAP)
        val fingerprint = MessageDigest.getInstance("SHA-256")
            .digest(keyPair.public.encoded)
            .take(16)
            .joinToString(":") { "%02X".format(it) }
        val identity = LocalIdentity(
            userId = UUID.randomUUID().toString(),
            username = username.trim().removePrefix("@"),
            displayName = displayName.trim(),
            deviceId = UUID.randomUUID().toString(),
            publicIdentityKey = publicKey,
            fingerprint = fingerprint,
            recoveryCreated = false,
        )
        context.identityDataStore.edit { p ->
            p[Keys.userId] = identity.userId
            p[Keys.username] = identity.username
            p[Keys.displayName] = identity.displayName
            p[Keys.deviceId] = identity.deviceId
            p[Keys.publicKey] = identity.publicIdentityKey
            p[Keys.fingerprint] = identity.fingerprint
            p[Keys.recoveryCreated] = identity.recoveryCreated
            p[Keys.onboardingComplete] = true
        }
        return identity
    }
}
