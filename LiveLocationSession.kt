package com.example.model

data class LiveLocationSession(
    val sessionId: String,
    val userId: String,
    val userName: String,
    val latitude: Double,
    val longitude: Double,
    val durationMinutes: Int,
    val remainingSeconds: Int,
    val lastUpdated: String
)

data class SecurityDeviceSession(
    val deviceId: String,
    val deviceName: String,
    val deviceType: String,
    val locationRegion: String,
    val lastActiveTime: String,
    val isCurrentDevice: Boolean = false
)
