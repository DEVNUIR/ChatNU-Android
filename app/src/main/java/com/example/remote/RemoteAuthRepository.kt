package com.example.remote

import android.os.Build
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
    private val apiClient: ApiClient
) {
    private val _currentUser = MutableStateFlow(tokenStore.loadUser())
    val currentUser: StateFlow<User?> = _currentUser.asStateFlow()

    private val _isLoggedIn = MutableStateFlow(tokenStore.accessToken != null && _currentUser.value != null)
    val isLoggedIn: StateFlow<Boolean> = _isLoggedIn.asStateFlow()

    suspend fun login(username: String, password: String): AuthResult {
        return runCatching {
            val response = apiClient.api.login(
                LoginRequest(
                    username = username.trim().lowercase(),
                    password = password,
                    deviceName = deviceName()
                )
            )
            persist(response)
            AuthResult(success = true)
        }.getOrElse { AuthResult(success = false, error = readableError(it)) }
    }

    suspend fun register(username: String, password: String, displayName: String): AuthResult {
        return runCatching {
            val response = apiClient.api.register(
                RegisterRequest(
                    username = username.trim().lowercase(),
                    password = password,
                    displayName = displayName.trim(),
                    deviceName = deviceName()
                )
            )
            persist(response)
            AuthResult(success = true, recoveryCode = response.recoveryCode)
        }.getOrElse { AuthResult(success = false, error = readableError(it)) }
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

    private fun persist(response: AuthResponse) {
        tokenStore.accessToken = response.accessToken
        tokenStore.refreshToken = response.refreshToken
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
