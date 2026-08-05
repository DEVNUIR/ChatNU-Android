package com.devnu.chatnu.core.work

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.NetworkType
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import androidx.work.Constraints
import com.devnu.chatnu.ChatNuApplication
import java.util.concurrent.TimeUnit

class OutboxWorker(appContext: Context, params: WorkerParameters) : CoroutineWorker(appContext, params) {
    override suspend fun doWork(): Result {
        val app = applicationContext as ChatNuApplication
        return runCatching {
            app.container.chatRepository.flushOutbox()
            app.container.chatRepository.syncFromServer()
        }.fold(onSuccess = { Result.success() }, onFailure = { Result.retry() })
    }
}

object OutboxScheduler {
    fun schedule(context: Context) {
        val constraints = Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build()
        val request = PeriodicWorkRequestBuilder<OutboxWorker>(15, TimeUnit.MINUTES)
            .setConstraints(constraints)
            .build()
        WorkManager.getInstance(context).enqueueUniquePeriodicWork(
            "chatnu-outbox-sync",
            ExistingPeriodicWorkPolicy.UPDATE,
            request,
        )
    }
}
