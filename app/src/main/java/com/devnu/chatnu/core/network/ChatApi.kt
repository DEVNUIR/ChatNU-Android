package com.devnu.chatnu.core.network

import io.ktor.client.HttpClient
import io.ktor.client.call.body
import io.ktor.client.plugins.HttpTimeout
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.client.plugins.defaultRequest
import io.ktor.client.request.get
import io.ktor.client.request.post
import io.ktor.client.request.setBody
import io.ktor.http.ContentType
import io.ktor.http.contentType
import io.ktor.serialization.kotlinx.json.json
import kotlinx.serialization.json.Json

interface ChatApi {
    suspend fun health(): NetworkResult<HealthResponse>
    suspend fun register(request: RegisterRequest): NetworkResult<RegisterResponse>
    suspend fun sendEnvelope(envelope: CipherEnvelope): NetworkResult<Unit>
}

class KtorChatApi(private val config: ServerConfig) : ChatApi {
    private val client = HttpClient {
        install(ContentNegotiation) { json(Json { ignoreUnknownKeys = true }) }
        install(HttpTimeout) {
            requestTimeoutMillis = config.connectTimeoutMs
            connectTimeoutMillis = config.connectTimeoutMs
            socketTimeoutMillis = 30_000
        }
        defaultRequest {
            url(config.apiBaseUrl)
            contentType(ContentType.Application.Json)
        }
    }

    override suspend fun health() = runCatching {
        client.get("/api/v1/health").body<HealthResponse>()
    }.fold(NetworkResult::Success, NetworkResult::Failure)

    override suspend fun register(request: RegisterRequest) = runCatching {
        client.post("/api/v1/auth/register") { setBody(request) }.body<RegisterResponse>()
    }.fold(NetworkResult::Success, NetworkResult::Failure)

    override suspend fun sendEnvelope(envelope: CipherEnvelope) = runCatching {
        client.post("/api/v1/messages") { setBody(envelope) }
        Unit
    }.fold(NetworkResult::Success, NetworkResult::Failure)
}
