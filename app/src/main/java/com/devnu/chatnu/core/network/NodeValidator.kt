package com.devnu.chatnu.core.network

import io.ktor.client.HttpClient
import io.ktor.client.call.body
import io.ktor.client.plugins.HttpTimeout
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.client.request.get
import io.ktor.serialization.kotlinx.json.json
import kotlinx.serialization.json.Json
import kotlin.system.measureTimeMillis

class NodeValidator {
    private val client = HttpClient {
        install(ContentNegotiation) { json(Json { ignoreUnknownKeys = true }) }
        install(HttpTimeout) {
            requestTimeoutMillis = 8_000
            connectTimeoutMillis = 5_000
            socketTimeoutMillis = 8_000
        }
    }

    suspend fun validate(host: String): ValidatedNode {
        val normalized = host.trim().removeSuffix("/")
        require(normalized.startsWith("https://")) { "Relay nodes require HTTPS" }
        lateinit var health: HealthResponse
        val latency = measureTimeMillis {
            health = client.get("$normalized/api/v1/health").body()
        }
        require(health.status == "ok" || health.status == "degraded") { "Node health check failed" }
        require(health.version.substringBefore('.').toIntOrNull() == 0) { "Incompatible ChatNU protocol" }
        return ValidatedNode(normalized, normalized.replaceFirst("https://", "wss://") + "/realtime", latency.toInt(), health.nodeId)
    }
}

data class ValidatedNode(val host: String, val websocketUrl: String, val latencyMs: Int, val nodeId: String)
