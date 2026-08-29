package com.example.ui.components

import androidx.compose.animation.*
import androidx.compose.animation.core.tween
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowDownward
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Shield
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.example.model.Message
import com.example.model.MessageType
import com.example.ui.theme.ChatNuAccent
import com.example.ui.theme.ChatNuEncryptedGreen
import kotlinx.coroutines.launch

@Composable
fun ChatMessageList(
    messages: List<Message>,
    modifier: Modifier = Modifier,
    onViewOnceClick: (Message) -> Unit = {},
    onReactionSelect: (messageId: String, emoji: String) -> Unit = { _, _ -> },
    onTogglePin: (messageId: String) -> Unit = {}
) {
    val listState = rememberLazyListState()
    val coroutineScope = rememberCoroutineScope()
    val isDark = isSystemInDarkTheme()

    // Auto-scroll to bottom on new message
    LaunchedEffect(messages.size) {
        if (messages.isNotEmpty()) {
            listState.animateScrollToItem(messages.size - 1)
        }
    }

    val isScrolledUp by remember {
        derivedStateOf {
            val lastVisibleIndex = listState.layoutInfo.visibleItemsInfo.lastOrNull()?.index ?: 0
            messages.isNotEmpty() && lastVisibleIndex < messages.size - 2
        }
    }

    Box(modifier = modifier.fillMaxSize()) {
        LazyColumn(
            state = listState,
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 12.dp),
            contentPadding = PaddingValues(top = 12.dp, bottom = 20.dp),
            verticalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            // E2EE Banner Header
            item(key = "e2ee_header") {
                SystemMessagePill(
                    text = "Messages and calls are end-to-end encrypted with Signal protocol & devnu.ir keys. No one outside of this chat can read or listen.",
                    icon = Icons.Default.Shield,
                    iconColor = ChatNuEncryptedGreen,
                    isSecurityEvent = true,
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
                )
            }

            // Date divider placeholder for top
            item(key = "date_header_initial") {
                DateDividerPill(dateText = "Today")
            }

            itemsIndexed(
                items = messages,
                key = { _, message -> message.id }
            ) { index, msg ->
                // Check if message is a system message
                if (msg.type == MessageType.SYSTEM_KEY_CHANGE) {
                    SystemMessagePill(
                        text = msg.text,
                        icon = Icons.Default.Lock,
                        iconColor = ChatNuAccent,
                        isSecurityEvent = true
                    )
                } else {
                    // Animated entrance transition for chat message bubble
                    AnimatedVisibility(
                        visible = true,
                        enter = fadeIn(animationSpec = tween(300)) + slideInVertically(
                            animationSpec = tween(300),
                            initialOffsetY = { 40 }
                        )
                    ) {
                        MessageBubble(
                            message = msg,
                            isOutgoing = msg.senderId == "usr_me",
                            onViewOnceClick = { onViewOnceClick(msg) },
                            onReactionSelect = { emoji -> onReactionSelect(msg.id, emoji) },
                            onTogglePin = { onTogglePin(msg.id) }
                        )
                    }
                }
            }
        }

        // Animated Glass Floating Button to scroll to latest message
        AnimatedVisibility(
            visible = isScrolledUp,
            enter = fadeIn() + scaleIn(),
            exit = fadeOut() + scaleOut(),
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .padding(bottom = 16.dp, end = 16.dp)
        ) {
            Surface(
                onClick = {
                    coroutineScope.launch {
                        listState.animateScrollToItem(messages.size - 1)
                    }
                },
                shape = CircleShape,
                color = if (isDark) Color(0xDD1F2937) else Color(0xDDFFFFFF),
                border = BorderStroke(1.dp, if (isDark) Color(0x33FFFFFF) else Color(0x33000000)),
                shadowElevation = 6.dp,
                modifier = Modifier.size(44.dp)
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(
                        imageVector = Icons.Default.ArrowDownward,
                        contentDescription = "Scroll to bottom",
                        tint = ChatNuAccent,
                        modifier = Modifier.size(20.dp)
                    )
                }
            }
        }
    }
}
