package com.example.remote

data class ServerInfoResponse(
    val protocol: String,
    val version: Int,
    val instanceName: String,
    val instanceId: String,
    val publicBaseUrl: String? = null,
    val registrationOpen: Boolean = true,
    val federation: Boolean = false,
    val addressFormat: String = "username@server"
)
