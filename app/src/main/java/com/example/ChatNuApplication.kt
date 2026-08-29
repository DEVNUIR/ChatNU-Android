package com.example

import android.app.Application
import coil.ImageLoader
import coil.ImageLoaderFactory
import com.example.remote.SecureCacheCleaner
import com.google.firebase.FirebaseApp
import com.google.firebase.FirebaseOptions
import okhttp3.OkHttpClient

class ChatNuApplication : Application(), ImageLoaderFactory {
    override fun onCreate() {
        super.onCreate()
        SecureCacheCleaner.cleanOnColdStart(this)
        initializeFirebaseIfConfigured()
    }

    /**
     * Coil is also used for map tiles. The public OpenStreetMap tile service explicitly requires
     * an identifiable application User-Agent; generic OkHttp/Coil identifiers can be blocked.
     * Keeping the header at the shared image-loader boundary also preserves normal Coil memory and
     * disk caching instead of bypassing cache for every map message.
     */
    override fun newImageLoader(): ImageLoader = ImageLoader.Builder(this)
        .okHttpClient {
            OkHttpClient.Builder()
                .addNetworkInterceptor { chain ->
                    val request = chain.request().newBuilder()
                        .header(
                            "User-Agent",
                            "ChatNU-Android/${BuildConfig.VERSION_NAME} (ir.devnu.chatnu; https://devnu.ir)"
                        )
                        .build()
                    chain.proceed(request)
                }
                .build()
        }
        .build()

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
