package com.devnu.chatnu.core.network

import com.devnu.chatnu.BuildConfig

data class ServerConfig(
    val apiBaseUrl: String = BuildConfig.DEFAULT_API_URL,
    val websocketUrl: String = BuildConfig.DEFAULT_WS_URL,
    val connectTimeoutMs: Long = 15_000,
    val heartbeatIntervalMs: Long = 25_000,
)
