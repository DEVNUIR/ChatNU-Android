package com.example.data

import com.example.model.Account
import com.example.model.User
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

object AccountManager {
    private val demoAccounts = listOf(
        Account(
            id = "acc_01",
            username = "clash8575",
            displayName = "Mohammad (devnu.ir)",
            avatarUrl = "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150",
            relayServerUrl = "wss://relay.devnu.ir",
            relayLatencyMs = 12,
            relayStatus = "CONNECTED",
            identityKeyFingerprint = "7F8B-9C0D-1E2F-3A4B",
            unreadCount = 2,
            isPrimary = true
        ),
        Account(
            id = "acc_02",
            username = "reza_privacy",
            displayName = "Reza (Personal Node)",
            avatarUrl = "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150",
            relayServerUrl = "wss://relay.private-node.org",
            relayLatencyMs = 28,
            relayStatus = "CONNECTED",
            identityKeyFingerprint = "982A-4F10-BC77-1100",
            unreadCount = 0
        ),
        Account(
            id = "acc_03",
            username = "crypto_vault",
            displayName = "Anonymous Vault",
            avatarUrl = "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=150",
            relayServerUrl = "wss://decentralized.chat-relay.net",
            relayLatencyMs = 45,
            relayStatus = "CONNECTED",
            identityKeyFingerprint = "E2EE-8899-7766-5544",
            unreadCount = 5
        )
    )

    private val _accounts = MutableStateFlow<List<Account>>(demoAccounts)
    val accounts: StateFlow<List<Account>> = _accounts.asStateFlow()

    private val _activeAccountId = MutableStateFlow("acc_01")
    val activeAccountId: StateFlow<String> = _activeAccountId.asStateFlow()

    val activeAccount: Account
        get() = _accounts.value.find { it.id == _activeAccountId.value }
            ?: _accounts.value.firstOrNull()
            ?: Account(
                id = "unknown",
                username = "unknown",
                displayName = "ChatNU User",
                avatarUrl = ""
            )

    private val _selectedLanguage = MutableStateFlow("English")
    val selectedLanguage: StateFlow<String> = _selectedLanguage.asStateFlow()

    fun setLanguage(lang: String) {
        _selectedLanguage.value = lang
    }

    /**
     * Binds the legacy drawer/account UI to the authenticated server user.
     * The old demo account switcher is intentionally collapsed to the real session account
     * in production mode so the UI cannot display a fake identity after login.
     */
    fun bindRemoteUser(user: User) {
        val account = Account(
            id = user.id,
            username = user.username,
            displayName = user.displayName,
            avatarUrl = user.avatarUrl.orEmpty(),
            bio = user.bio ?: "ChatNU User",
            relayServerUrl = "wss://api.devnu.ir/realtime",
            relayLatencyMs = 0,
            relayStatus = "CONNECTED",
            identityKeyFingerprint = user.identityKeyFingerprint,
            unreadCount = 0,
            isPrimary = true
        )
        _accounts.value = listOf(account)
        _activeAccountId.value = account.id
    }

    fun updateActiveAccountProfile(
        displayName: String,
        username: String,
        bio: String,
        avatarUrl: String,
        relayServerUrl: String = activeAccount.relayServerUrl
    ) {
        val cleanUsername = if (username.startsWith("@")) username.drop(1) else username
        val formattedRelay = if (relayServerUrl.startsWith("wss://") || relayServerUrl.startsWith("ws://")) relayServerUrl else "wss://$relayServerUrl"

        _accounts.value = _accounts.value.map { acc ->
            if (acc.id == _activeAccountId.value) {
                acc.copy(
                    displayName = displayName.ifBlank { acc.displayName },
                    username = cleanUsername.ifBlank { acc.username },
                    bio = bio.ifBlank { acc.bio },
                    avatarUrl = avatarUrl.ifBlank { acc.avatarUrl },
                    relayServerUrl = formattedRelay
                )
            } else acc
        }
    }

    fun switchAccount(accountId: String) {
        if (_accounts.value.any { it.id == accountId }) {
            _activeAccountId.value = accountId
        }
    }

    fun addAccount(
        username: String,
        displayName: String,
        relayUrl: String,
        avatarUrl: String? = null
    ): Boolean {
        if (_accounts.value.size >= 10) return false

        val formattedRelay = if (relayUrl.startsWith("wss://") || relayUrl.startsWith("ws://")) relayUrl else "wss://$relayUrl"
        val cleanUsername = if (username.startsWith("@")) username.drop(1) else username

        val newAccount = Account(
            id = "acc_" + System.currentTimeMillis(),
            username = cleanUsername,
            displayName = displayName.ifBlank { "@$cleanUsername" },
            avatarUrl = avatarUrl ?: "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150",
            relayServerUrl = formattedRelay,
            relayLatencyMs = (10..40).random(),
            relayStatus = "CONNECTED",
            identityKeyFingerprint = generateRandomFingerprint(),
            unreadCount = 0
        )

        _accounts.value = _accounts.value + newAccount
        _activeAccountId.value = newAccount.id
        return true
    }

    fun removeAccount(accountId: String) {
        if (_accounts.value.size <= 1) return
        _accounts.value = _accounts.value.filterNot { it.id == accountId }
        if (_activeAccountId.value == accountId) {
            _activeAccountId.value = _accounts.value.first().id
        }
    }

    private fun generateRandomFingerprint(): String {
        val chars = "0123456789ABCDEF"
        fun section() = (1..4).map { chars.random() }.joinToString("")
        return "${section()}-${section()}-${section()}-${section()}"
    }

    fun toUser(account: Account): User = User(
        id = account.id,
        username = account.username,
        displayName = account.displayName,
        avatarUrl = account.avatarUrl,
        bio = account.bio,
        identityKeyFingerprint = account.identityKeyFingerprint,
        isOnline = true
    )
}
