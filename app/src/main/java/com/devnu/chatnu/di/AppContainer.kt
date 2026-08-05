package com.devnu.chatnu.di

import android.content.Context
import com.devnu.chatnu.core.crypto.DevelopmentPayloadCipher
import com.devnu.chatnu.core.database.DatabaseFactory
import com.devnu.chatnu.core.identity.IdentityStore
import com.devnu.chatnu.core.network.KtorChatApi
import com.devnu.chatnu.core.network.KtorRealtimeGateway
import com.devnu.chatnu.core.network.ServerConfig
import com.devnu.chatnu.data.LocalFirstChatRepository
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

class AppContainer(context: Context) {
    private val applicationScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private val database = DatabaseFactory.create(context)
    private val serverConfig = ServerConfig()
    private val api = KtorChatApi(serverConfig)
    private val realtime = KtorRealtimeGateway(serverConfig)

    val identityStore = IdentityStore(context)
    val chatRepository = LocalFirstChatRepository(
        dao = database.chatDao(),
        api = api,
        realtime = realtime,
        cipher = DevelopmentPayloadCipher(),
        applicationScope = applicationScope,
    )

    fun start() {
        applicationScope.launch { chatRepository.seedIfEmpty() }
        chatRepository.startRealtime()
    }
}
