package com.example.model

data class User(
    val id: String,
    val username: String,
    val displayName: String,
    val avatarUrl: String? = null,
    val bio: String? = null,
    val isOnline: Boolean = false,
    val lastSeen: String = "recently",
    val identityKeyFingerprint: String = "A1B2-C3D4-E5F6-7890"
)
