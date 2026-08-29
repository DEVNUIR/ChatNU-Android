package com.example.data

import com.example.model.*

object MockBackend {
    val currentUser = User(
        id = "usr_me",
        username = "clash8575",
        displayName = "Mohammad (devnu.ir)",
        avatarUrl = "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150",
        bio = "Lead Engineer @ devnu.ir | Privacy First",
        isOnline = true,
        identityKeyFingerprint = "7F8B-9C0D-1E2F-3A4B"
    )

    val mockUsers = listOf(
        User(
            id = "usr_ali",
            username = "ali_devnu",
            displayName = "Ali Rezaei",
            avatarUrl = "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150",
            bio = "Backend Architect | devnu.ir",
            isOnline = true,
            lastSeen = "online",
            identityKeyFingerprint = "1122-3344-5566-7788"
        ),
        User(
            id = "usr_sara",
            username = "sara_design",
            displayName = "Sara Ahmadi",
            avatarUrl = "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150",
            bio = "UI/UX & Product Design",
            isOnline = false,
            lastSeen = "10m ago",
            identityKeyFingerprint = "9988-7766-5544-3322"
        ),
        User(
            id = "usr_support",
            username = "devnu_official",
            displayName = "DevNU Official Support",
            avatarUrl = "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=150",
            bio = "Official Verified Channel for devnu.ir updates",
            isOnline = true,
            identityKeyFingerprint = "DEVN-U001-SEC2-CHAT"
        )
    )

    val initialConversations = listOf(
        Conversation(
            id = "conv_ali",
            title = "Ali Rezaei",
            type = ConversationType.DIRECT,
            avatarUrl = "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150",
            lastMessageText = "سلام! API جدید devnu.ir آماده است.",
            lastMessageTime = "10:42",
            unreadCount = 2,
            isPinned = true,
            isEncrypted = true,
            members = listOf(currentUser, mockUsers[0])
        ),
        Conversation(
            id = "conv_devnu_team",
            title = "DevNU Core Engineering",
            type = ConversationType.GROUP,
            avatarUrl = "https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=150",
            lastMessageText = "Sara: New mockups uploaded to devnu.ir",
            lastMessageTime = "Yesterday",
            unreadCount = 0,
            isPinned = true,
            isEncrypted = true,
            members = listOf(currentUser, mockUsers[0], mockUsers[1])
        ),
        Conversation(
            id = "conv_sara",
            title = "Sara Ahmadi",
            type = ConversationType.DIRECT,
            avatarUrl = "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150",
            lastMessageText = "📷 View-once image received",
            lastMessageTime = "09:15",
            unreadCount = 0,
            isPinned = false,
            isEncrypted = true,
            members = listOf(currentUser, mockUsers[1])
        ),
        Conversation(
            id = "conv_support",
            title = "DevNU Official Support",
            type = ConversationType.DIRECT,
            avatarUrl = "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=150",
            lastMessageText = "Welcome to ChatNU! End-to-End Encryption active.",
            lastMessageTime = "Jul 31",
            unreadCount = 0,
            isPinned = false,
            isEncrypted = true,
            members = listOf(currentUser, mockUsers[2])
        )
    )

    val initialMessagesMap = mutableMapOf(
        "conv_ali" to mutableListOf(
            Message(
                id = "sys_msg_100",
                conversationId = "conv_ali",
                senderId = "system",
                senderName = "",
                text = "Safety number for Ali Rezaei updated. Tap to verify E2EE identity key fingerprint (7F8B-9C0D).",
                type = MessageType.SYSTEM_KEY_CHANGE,
                timestamp = "10:35"
            ),
            Message(
                id = "msg_101",
                conversationId = "conv_ali",
                senderId = "usr_ali",
                senderName = "Ali Rezaei",
                text = "سلام محمد جان! وضعیت سرور api.devnu.ir چطوره؟",
                timestamp = "10:38"
            ),
            Message(
                id = "msg_102",
                conversationId = "conv_ali",
                senderId = "usr_me",
                senderName = "Mohammad",
                text = "سلام علی! همه اندپointها روی devnu.ir فعال هستند و WebSocket روشنه.",
                timestamp = "10:40"
            ),
            Message(
                id = "msg_103",
                conversationId = "conv_ali",
                senderId = "usr_ali",
                senderName = "Ali Rezaei",
                text = "عالیه! پیام صوتی زیر رو چک کن:",
                timestamp = "10:41"
            ),
            Message(
                id = "msg_104",
                conversationId = "conv_ali",
                senderId = "usr_ali",
                senderName = "Ali Rezaei",
                text = "[Voice Message]",
                type = MessageType.VOICE,
                timestamp = "10:41",
                voiceDurationSeconds = 14,
                voiceWaveform = listOf(0.2f, 0.5f, 0.8f, 0.3f, 0.9f, 0.4f, 0.7f, 0.6f, 0.3f, 0.8f, 0.4f)
            ),
            Message(
                id = "msg_105",
                conversationId = "conv_ali",
                senderId = "usr_ali",
                senderName = "Ali Rezaei",
                text = "مستندات معماری و کلیدهای رمزنگاری جدید رو به صورت فایل ارسال کردم:",
                timestamp = "10:42"
            ),
            Message(
                id = "msg_106",
                conversationId = "conv_ali",
                senderId = "usr_ali",
                senderName = "Ali Rezaei",
                text = "Signal_E2EE_Architecture.pdf",
                type = MessageType.FILE,
                timestamp = "10:43",
                fileName = "Signal_E2EE_Architecture.pdf",
                fileSize = "4.8 MB",
                fileExtension = "pdf"
            ),
            Message(
                id = "msg_107",
                conversationId = "conv_ali",
                senderId = "usr_me",
                senderName = "Mohammad",
                text = "ممنون علی جان! سورس‌کد ماژول گلسمورفیسم iOS رو هم برات فرستادم:",
                timestamp = "10:44"
            ),
            Message(
                id = "msg_108",
                conversationId = "conv_ali",
                senderId = "usr_me",
                senderName = "Mohammad",
                text = "iOS_Glassmorphic_UI_Kit.zip",
                type = MessageType.FILE,
                timestamp = "10:45",
                fileName = "iOS_Glassmorphic_UI_Kit.zip",
                fileSize = "12.4 MB",
                fileExtension = "zip"
            )
        ),
        "conv_sara" to mutableListOf(
            Message(
                id = "msg_201",
                conversationId = "conv_sara",
                senderId = "usr_sara",
                senderName = "Sara Ahmadi",
                text = "Hi Mohammad! I sent a confidential design preview.",
                timestamp = "09:14"
            ),
            Message(
                id = "msg_202",
                conversationId = "conv_sara",
                senderId = "usr_sara",
                senderName = "Sara Ahmadi",
                text = "Tap to view (View Once)",
                type = MessageType.VIEW_ONCE_IMAGE,
                timestamp = "09:15",
                mediaUrl = "https://images.unsplash.com/photo-1507238691740-187a5b1d37b8?w=800",
                isViewOnceOpened = false
            )
        ),
        "conv_devnu_team" to mutableListOf(
            Message(
                id = "msg_301",
                conversationId = "conv_devnu_team",
                senderId = "usr_sara",
                senderName = "Sara",
                text = "Sara: New mockups uploaded to devnu.ir",
                timestamp = "Yesterday"
            ),
            Message(
                id = "msg_302",
                conversationId = "conv_devnu_team",
                senderId = "usr_ali",
                senderName = "Ali",
                text = "📍 Live location sharing active",
                type = MessageType.LIVE_LOCATION,
                timestamp = "Yesterday",
                latitude = 35.6892,
                longitude = 51.3890
            )
        ),
        "conv_support" to mutableListOf(
            Message(
                id = "msg_401",
                conversationId = "conv_support",
                senderId = "usr_support",
                senderName = "DevNU Support",
                text = "Welcome to ChatNU! Your sessions are secured via E2EE Signal protocol and devnu.ir infrastructure.",
                timestamp = "Jul 31"
            )
        )
    )

    val mockActiveSessions = listOf(
        SecurityDeviceSession(
            deviceId = "dev_01",
            deviceName = "Samsung Galaxy S24 Ultra (Current)",
            deviceType = "Android 14",
            locationRegion = "Tehran, Iran (api.devnu.ir)",
            lastActiveTime = "Active now",
            isCurrentDevice = true
        ),
        SecurityDeviceSession(
            deviceId = "dev_02",
            deviceName = "ChatNU Desktop Web App",
            deviceType = "Chrome / Linux",
            locationRegion = "Tehran, Iran",
            lastActiveTime = "2 hours ago",
            isCurrentDevice = false
        )
    )
}
