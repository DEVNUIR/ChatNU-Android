package com.devnu.chatnu.core.session

import com.devnu.chatnu.core.identity.IdentityStore
import com.devnu.chatnu.core.network.ChallengeRequest
import com.devnu.chatnu.core.network.ChatApi
import com.devnu.chatnu.core.network.NetworkResult
import com.devnu.chatnu.core.network.RegisterRequest
import com.devnu.chatnu.core.network.VerifyChallengeRequest
import kotlinx.coroutines.flow.first

class AuthManager(
    private val identityStore: IdentityStore,
    private val sessionStore: SessionStore,
    private val api: ChatApi,
) {
    suspend fun ensureSession(): String? {
        sessionStore.accessToken()?.let { return it }
        val identity = identityStore.identity.first() ?: return null
        return when (val registration = api.register(RegisterRequest(
            username = identity.username,
            displayName = identity.displayName,
            deviceId = identity.deviceId,
            publicIdentityKey = identity.publicIdentityKey,
        ))) {
            is NetworkResult.Success -> {
                identityStore.updateServerUserId(registration.value.userId)
                sessionStore.saveTokens(registration.value.accessToken, registration.value.refreshToken)
                registration.value.accessToken
            }
            is NetworkResult.Failure -> authenticateExistingDevice(identity.username, identity.deviceId)
        }
    }

    private suspend fun authenticateExistingDevice(username: String, deviceId: String): String? {
        val identity = identityStore.identity.first() ?: return null
        val challenge = when (val result = api.challenge(ChallengeRequest(username, deviceId))) {
            is NetworkResult.Success -> result.value
            is NetworkResult.Failure -> return null
        }
        val signature = identityStore.sign(identity, challenge.nonce)
        return when (val result = api.verifyChallenge(VerifyChallengeRequest(
            username = username,
            deviceId = deviceId,
            challengeId = challenge.challengeId,
            signature = signature,
        ))) {
            is NetworkResult.Success -> {
                sessionStore.saveTokens(result.value.accessToken, result.value.refreshToken)
                result.value.accessToken
            }
            is NetworkResult.Failure -> null
        }
    }
}
