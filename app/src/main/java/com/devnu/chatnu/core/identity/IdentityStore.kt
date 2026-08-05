package com.devnu.chatnu.core.identity

import android.content.Context
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.devnu.chatnu.core.model.LocalIdentity
import java.security.MessageDigest
import java.util.UUID
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

private val Context.identityDataStore by preferencesDataStore("identity")

class IdentityStore(
    private val context: Context,
    private val keyManager: IdentityKeyManager,
) {
    private object Keys {
        val userId = stringPreferencesKey("user_id")
        val username = stringPreferencesKey("username")
        val displayName = stringPreferencesKey("display_name")
        val deviceId = stringPreferencesKey("device_id")
        val keyAlias = stringPreferencesKey("key_alias")
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
            keyAlias = p[Keys.keyAlias].orEmpty(),
            publicIdentityKey = p[Keys.publicKey].orEmpty(),
            fingerprint = p[Keys.fingerprint].orEmpty(),
            recoveryCreated = p[Keys.recoveryCreated] ?: false,
        )
    }

    val onboardingComplete: Flow<Boolean> = context.identityDataStore.data.map { it[Keys.onboardingComplete] ?: false }

    suspend fun createIdentity(username: String, displayName: String): LocalIdentity {
        val deviceId = UUID.randomUUID().toString()
        val keyAlias = "chatnu_identity_$deviceId"
        val publicKey = keyManager.ensureKey(keyAlias)
        val fingerprint = MessageDigest.getInstance("SHA-256")
            .digest(android.util.Base64.decode(publicKey, android.util.Base64.NO_WRAP))
            .take(16)
            .joinToString(":") { "%02X".format(it) }
        val identity = LocalIdentity(
            userId = UUID.randomUUID().toString(),
            username = username.trim().removePrefix("@"),
            displayName = displayName.trim(),
            deviceId = deviceId,
            keyAlias = keyAlias,
            publicIdentityKey = publicKey,
            fingerprint = fingerprint,
            recoveryCreated = false,
        )
        save(identity)
        return identity
    }

    suspend fun updateServerUserId(userId: String) {
        context.identityDataStore.edit { it[Keys.userId] = userId }
    }

    fun sign(identity: LocalIdentity, challenge: String): String = keyManager.sign(identity.keyAlias, challenge)

    private suspend fun save(identity: LocalIdentity) {
        context.identityDataStore.edit { p ->
            p[Keys.userId] = identity.userId
            p[Keys.username] = identity.username
            p[Keys.displayName] = identity.displayName
            p[Keys.deviceId] = identity.deviceId
            p[Keys.keyAlias] = identity.keyAlias
            p[Keys.publicKey] = identity.publicIdentityKey
            p[Keys.fingerprint] = identity.fingerprint
            p[Keys.recoveryCreated] = identity.recoveryCreated
            p[Keys.onboardingComplete] = true
        }
    }
}
