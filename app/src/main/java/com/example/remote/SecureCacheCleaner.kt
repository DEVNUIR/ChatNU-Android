package com.example.remote

import android.content.Context
import java.io.File

/** Best-effort cleanup for plaintext media that only ever belongs in app-private cache storage. */
object SecureCacheCleaner {
    private val sensitiveCacheDirs = listOf(
        "chatnu_attachments",
        "chatnu_recordings",
        "chatnu_capture"
    )

    fun cleanOnColdStart(context: Context) {
        sensitiveCacheDirs.forEach { name ->
            runCatching { File(context.cacheDir, name).deleteRecursively() }
        }
    }
}
