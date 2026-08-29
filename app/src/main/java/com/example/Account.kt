package com.example.model

data class Account(
    val id: String,
    val username: String,
    val displayName: String,
    val avatarUrl: String,
    val bio: String = "Available • ChatNU User",
    val relayServerUrl: String = "wss://relay.devnu.ir",
    val relayLatencyMs: Int = 14,
    val relayStatus: String = "CONNECTED",
    val identityKeyFingerprint: String = "7F8B-9C0D-1E2F-3A4B",
    val unreadCount: Int = 0,
    val isPrimary: Boolean = false
)
