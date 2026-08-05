package com.devnu.chatnu.core.network

import com.devnu.chatnu.core.model.ConnectionState
import io.ktor.client.HttpClient
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.client.plugins.websocket.WebSockets
import io.ktor.client.plugins.websocket.webSocket
import io.ktor.serialization.kotlinx.json.json
import io.ktor.websocket.Frame
import io.ktor.websocket.readText
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.serialization.json.Json

interface RealtimeGateway {
    val state: Flow<ConnectionState>
    val events: Flow<RealtimeEvent>
    suspend fun run(accessToken: String?)
    suspend fun disconnect()
}

class KtorRealtimeGateway(private val config: ServerConfig) : RealtimeGateway {
    private val json = Json { ignoreUnknownKeys = true }
    private val client = HttpClient {
        install(ContentNegotiation) { json(json) }
        install(WebSockets) { pingIntervalMillis = config.heartbeatIntervalMs }
    }
    private val mutableState = MutableStateFlow(ConnectionState.DISCONNECTED)
    private val mutableEvents = MutableSharedFlow<RealtimeEvent>(extraBufferCapacity = 64)
    @Volatile private var active = true

    override val state = mutableState.asStateFlow()
    override val events = mutableEvents.asSharedFlow()

    override suspend fun run(accessToken: String?) {
        var attempt = 0
        active = true
        while (active) {
            mutableState.value = ConnectionState.CONNECTING
            try {
                client.webSocket(urlString = config.websocketUrl, request = {
                    accessToken?.let { headers.append("Authorization", "Bearer $it") }
                }) {
                    attempt = 0
                    mutableState.value = ConnectionState.CONNECTED
                    for (frame in incoming) {
                        if (frame is Frame.Text) {
                            runCatching { json.decodeFromString<RealtimeEvent>(frame.readText()) }
                                .onSuccess { mutableEvents.emit(it) }
                        }
                    }
                }
            } catch (cancelled: CancellationException) {
                throw cancelled
            } catch (_: Throwable) {
                mutableState.value = ConnectionState.DEGRADED
                attempt++
                delay((1_000L shl attempt.coerceAtMost(5)).coerceAtMost(30_000L))
            }
        }
        mutableState.value = ConnectionState.DISCONNECTED
    }

    override suspend fun disconnect() {
        active = false
        client.close()
        mutableState.value = ConnectionState.DISCONNECTED
    }
}
