package com.example.remote

import android.os.Build
import com.example.crypto.DeviceE2ee
import com.example.model.User
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import retrofit2.HttpException

data class AuthResult(
    val success: Boolean,
    val recoveryCode: String? = null,
    val error: String? = null
)

class RemoteAuthRepository(
    private val tokenStore: TokenStore,
    private val apiClient: ApiClient,
    private val deviceE2ee: DeviceE2ee
) {
    private val _currentUser = MutableStateFlow(tokenStore.loadUser())
    val currentUser: StateFlow<User?> = _currentUser.asStateFlow()

    private val _isLoggedIn = MutableStateFlow(tokenStore.accessToken != null && _currentUser.value != null)
    val isLoggedIn: StateFlow<Boolean> = _isLoggedIn.asStateFlow()

    suspend fun login(username: String, password: String): AuthResult {
        val normalized = username.trim().lowercase()
        return runCatching {
            val response = apiClient.api.login(
                LoginRequest(
                    username = normalized,
                    password = password,
                    deviceName = deviceName(),
                    identityPublicKey = deviceE2ee.publicKeyBase64(normalized)
                )
            )
            persist(response, normalized)
            AuthResult(success = true)
        }.getOrElse { AuthResult(success = false, error = readableError(it)) }
    }

    suspend fun register(username: String, password: String, displayName: String): AuthResult {
        val normalized = username.trim().lowercase()
        return runCatching {
            val response = apiClient.api.register(
                RegisterRequest(
                    username = normalized,
                    password = password,
                    displayName = displayName.trim(),
                    deviceName = deviceName(),
                    identityPublicKey = deviceE2ee.publicKeyBase64(normalized)
                )
            )
            persist(response, normalized)
            AuthResult(success = true, recoveryCode = response.recoveryCode)
        }.getOrElse { AuthResult(success = false, error = readableError(it)) }
    }

    /** Ensures sessions created by an older ChatNU build receive a current device id and public key. */
    suspend fun ensureDeviceIdentity() {
        val user = _currentUser.value ?: return
        val session = apiClient.api.session()
        tokenStore.deviceId = session.deviceId
        tokenStore.cryptoAccount = user.username
        apiClient.api.updateIdentityKey(
            IdentityKeyRequest(deviceE2ee.publicKeyBase64(user.username))
        )
    }

    suspend fun registerPushToken(token: String?) {
        if (!_isLoggedIn.value) return
        apiClient.api.updatePushToken(PushTokenRequest(token))
    }

    suspend fun logout() {
        runCatching { apiClient.api.logout() }
        tokenStore.clear()
        _currentUser.value = null
        _isLoggedIn.value = false
    }

    fun forceLogout() {
        tokenStore.clear()
        _currentUser.value = null
        _isLoggedIn.value = false
    }

    private fun persist(response: AuthResponse, cryptoAccount: String) {
        tokenStore.accessToken = response.accessToken
        tokenStore.refreshToken = response.refreshToken
        tokenStore.deviceId = response.deviceId
        tokenStore.cryptoAccount = cryptoAccount
        tokenStore.saveUser(response.user)
        _currentUser.value = response.user.toModel()
        _isLoggedIn.value = true
    }

    private fun readableError(error: Throwable): String {
        if (error is HttpException) {
            return when (error.code()) {
                400 -> "اطلاعات واردشده معتبر نیست."
                401 -> "نام کاربری یا رمز عبور اشتباه است."
                409 -> "این نام کاربری قبلاً گرفته شده."
                429 -> "درخواست‌ها خیلی زیاد شده؛ کمی بعد دوباره امتحان کن."
                else -> "خطای سرور (${error.code()})"
            }
        }
        return error.message ?: "ارتباط با سرور برقرار نشد."
    }

    private fun deviceName(): String = "${Build.MANUFACTURER} ${Build.MODEL}".trim()
}

fun UserDto.toModel() = User(
    id = id,
    username = username,
    displayName = displayName,
    avatarUrl = avatarUrl,
    bio = bio,
    lastSeen = lastSeenAt ?: "recently"
)
