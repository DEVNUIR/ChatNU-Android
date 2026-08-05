package com.devnu.chatnu.core.database

import androidx.room.Database
import androidx.room.RoomDatabase

@Database(
    entities = [
        UserEntity::class,
        ConversationEntity::class,
        MessageEntity::class,
        RelayNodeEntity::class,
        OutboxEntity::class,
    ],
    version = 1,
    exportSchema = true,
)
abstract class ChatNuDatabase : RoomDatabase() {
    abstract fun chatDao(): ChatDao
}
