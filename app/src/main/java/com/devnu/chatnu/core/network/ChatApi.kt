package com.devnu.chatnu.core.network

import com.devnu.chatnu.core.session.SessionStore
import io.ktor.client.HttpClient
import io.ktor.client.call.body
import io.ktor.client.plugins.HttpTimeout
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.client.plugins.defaultRequest
import io.ktor.client.request.get
import io.ktor.client.request.header
import io.ktor.client.request.post
import io.ktor.client.request.setBody
import io.ktor.http.ContentType
import io.ktor.http.HttpHeaders
import io.ktor.http.contentType
import io.ktor.serialization.kotlinx.json.json
import kotlinx.serialization.json.Json

interface ChatApi {
    suspend fun health(): NetworkResult<HealthResponse>
    suspend fun register(request: RegisterRequest): NetworkResult<RegisterResponse>
    suspend fun challenge(request: ChallengeRequest): NetworkResult<ChallengeResponse>
    suspend fun verifyChallenge(request: VerifyChallengeRequest): NetworkResult<TokenResponse>
    suspend fun sendEnvelope(envelope: CipherEnvelope): NetworkResult<Unit>
    suspend fun sync(cursor: String?): NetworkResult<SyncPage>
}

class KtorChatApi(
    private val config: ServerConfig,
    private val sessionStore: SessionStore,
) : ChatApi {
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
            sessionStore.accessToken()?.let { header(HttpHeaders.Authorization, "Bearer $it") }
        }
    }

    override suspend fun health() = call { client.get("/api/v1/health").body<HealthResponse>() }
    override suspend fun register(request: RegisterRequest) = call { client.post("/api/v1/auth/register") { setBody(request) }.body<RegisterResponse>() }
    override suspend fun challenge(request: ChallengeRequest) = call { client.post("/api/v1/auth/challenge") { setBody(request) }.body<ChallengeResponse>() }
    override suspend fun verifyChallenge(request: VerifyChallengeRequest) = call { client.post("/api/v1/auth/verify") { setBody(request) }.body<TokenResponse>() }
    override suspend fun sendEnvelope(envelope: CipherEnvelope) = call { client.post("/api/v1/messages") { setBody(envelope) }; Unit }
    override suspend fun sync(cursor: String?) = call { client.get("/api/v1/sync") { cursor?.let { url.parameters.append("cursor", it) } }.body<SyncPage>() }

    private suspend fun <T> call(block: suspend () -> T): NetworkResult<T> = runCatching { block() }
        .fold(NetworkResult::Success, NetworkResult::Failure)
}
