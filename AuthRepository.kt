package com.example.data

import com.example.model.User
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

class AuthRepository {
    private val _currentUser = MutableStateFlow<User?>(MockBackend.currentUser)
    val currentUser: StateFlow<User?> = _currentUser.asStateFlow()

    private val _isLoggedIn = MutableStateFlow(true)
    val isLoggedIn: StateFlow<Boolean> = _isLoggedIn.asStateFlow()

    fun login(username: String, passwordHash: String): Boolean {
        _isLoggedIn.value = true
        _currentUser.value = MockBackend.currentUser.copy(username = username)
        return true
    }

    fun register(username: String, displayName: String): String {
        _isLoggedIn.value = true
        _currentUser.value = User(
            id = "usr_" + System.currentTimeMillis(),
            username = username,
            displayName = displayName,
            avatarUrl = "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150"
        )
        return "CHATNU-RCVR-9876-5432-1011"
    }

    fun logout() {
        _isLoggedIn.value = false
        _currentUser.value = null
    }
}
