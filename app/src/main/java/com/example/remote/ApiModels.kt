package com.example.remote

data class UserDto(
    val id: String,
    val username: String,
    val displayName: String,
    val avatarUrl: String? = null,
    val bio: String? = null,
    val lastSeenAt: String? = null
)

data class AuthResponse(
    val user: UserDto,
    val deviceId: String,
    val accessToken: String,
    val refreshToken: String,
    val expiresIn: Int,
    val recoveryCode: String? = null
)

data class RefreshResponse(
    val accessToken: String,
    val refreshToken: String,
    val expiresIn: Int
)

data class RegisterRequest(
    val username: String,
    val password: String,
    val displayName: String,
    val deviceName: String
)

data class LoginRequest(
    val username: String,
    val password: String,
    val deviceName: String
)

data class RefreshRequest(val refreshToken: String)

data class UsersResponse(val users: List<UserDto>)

data class ConversationDto(
    val id: String,
    val type: String,
    val title: String,
    val avatarUrl: String? = null,
    val members: List<UserDto> = emptyList(),
    val isPinned: Boolean = false,
    val isMuted: Boolean = false,
    val unreadCount: Int = 0,
    val updatedAt: String? = null,
    val lastMessage: MessageDto? = null
)

data class ConversationsResponse(val conversations: List<ConversationDto>)
data class ConversationResponse(val conversation: ConversationDto)
data class DirectConversationRequest(val username: String)
data class GroupConversationRequest(val title: String, val usernames: List<String> = emptyList())
data class ConversationPreferencesRequest(val isPinned: Boolean? = null, val isMuted: Boolean? = null)

data class MessageDto(
    val id: String,
    val clientId: String? = null,
    val conversationId: String,
    val senderId: String,
    val senderUsername: String? = null,
    val senderName: String,
    val type: String,
    val ciphertext: String,
    val nonce: String? = null,
    val protocolVersion: String? = null,
    val createdAt: String
)

data class MessagesResponse(val messages: List<MessageDto>)

data class SendMessageRequest(
    val conversationId: String,
    val clientId: String,
    val type: String,
    val ciphertext: String,
    val nonce: String? = null,
    val protocolVersion: String? = null,
    val metadata: Map<String, Any?>? = null
)

data class MessageResponse(val message: MessageDto, val duplicate: Boolean? = null)
data class ErrorResponse(val error: String? = null, val message: String? = null)
