package com.example

import android.app.Application
import com.example.remote.SecureCacheCleaner
import com.google.firebase.FirebaseApp
import com.google.firebase.FirebaseOptions

class ChatNuApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        SecureCacheCleaner.cleanOnColdStart(this)
        initializeFirebaseIfConfigured()
    }

    private fun initializeFirebaseIfConfigured() {
        if (FirebaseApp.getApps(this).isNotEmpty()) return
        val appId = BuildConfig.FIREBASE_APP_ID.trim()
        val apiKey = BuildConfig.FIREBASE_API_KEY.trim()
        val projectId = BuildConfig.FIREBASE_PROJECT_ID.trim()
        val senderId = BuildConfig.FIREBASE_SENDER_ID.trim()
        if (appId.isBlank() || apiKey.isBlank() || projectId.isBlank() || senderId.isBlank()) return

        val options = FirebaseOptions.Builder()
            .setApplicationId(appId)
            .setApiKey(apiKey)
            .setProjectId(projectId)
            .setGcmSenderId(senderId)
            .build()
        FirebaseApp.initializeApp(this, options)
    }
}
