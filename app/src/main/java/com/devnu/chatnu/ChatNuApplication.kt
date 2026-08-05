package com.devnu.chatnu

import android.app.Application
import com.devnu.chatnu.di.AppContainer

class ChatNuApplication : Application() {
    lateinit var container: AppContainer
        private set

    override fun onCreate() {
        super.onCreate()
        container = AppContainer(this)
        container.start()
    }
}
