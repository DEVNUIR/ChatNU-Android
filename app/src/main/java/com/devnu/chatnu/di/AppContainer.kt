package com.devnu.chatnu.di

import android.content.Context
import com.devnu.chatnu.core.crypto.DevelopmentPayloadCipher
import com.devnu.chatnu.core.database.DatabaseFactory
import com.devnu.chatnu.core.identity.IdentityKeyManager
import com.devnu.chatnu.core.identity.IdentityStore
import com.devnu.chatnu.core.network.KtorChatApi
import com.devnu.chatnu.core.network.KtorRealtimeGateway
import com.devnu.chatnu.core.network.NodeValidator
import com.devnu.chatnu.core.network.ServerConfig
import com.devnu.chatnu.core.session.AuthManager
import com.devnu.chatnu.core.session.SessionStore
import com.devnu.chatnu.core.work.OutboxScheduler
import com.devnu.chatnu.data.LocalFirstChatRepository
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

class AppContainer(private val context: Context) {
    private val applicationScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private val database = DatabaseFactory.create(context)
    private val serverConfig = ServerConfig()
    private val sessionStore = SessionStore(context)
    private val identityKeyManager = IdentityKeyManager()

    val identityStore = IdentityStore(context, identityKeyManager)
    private val api = KtorChatApi(serverConfig, sessionStore)
    private val realtime = KtorRealtimeGateway(serverConfig)
    private val authManager = AuthManager(identityStore, sessionStore, api)

    val chatRepository = LocalFirstChatRepository(
        dao = database.chatDao(),
        api = api,
        realtime = realtime,
        cipher = DevelopmentPayloadCipher(),
        identityStore = identityStore,
        sessionStore = sessionStore,
        nodeValidator = NodeValidator(),
        applicationScope = applicationScope,
    )

    fun start() {
        applicationScope.launch {
            chatRepository.seedIfEmpty()
            val token = authManager.ensureSession()
            chatRepository.startRealtime(token)
            chatRepository.syncFromServer()
        }
        OutboxScheduler.schedule(context)
    }
}
