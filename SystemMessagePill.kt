package com.example.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Shield
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.ui.theme.ChatNuAccentLight
import com.example.ui.theme.ChatNuEncryptedGreen
import com.example.ui.theme.isAppInDarkTheme

@Composable
fun SystemMessagePill(
    text: String,
    modifier: Modifier = Modifier,
    icon: ImageVector = Icons.Default.Lock,
    iconColor: Color = ChatNuEncryptedGreen,
    isSecurityEvent: Boolean = true
) {
    val isDark = isAppInDarkTheme()
    val bgColor = if (isDark) Color(0x990F172A) else Color(0xCCFFFFFF)
    val borderColor = if (isDark) Color(0x33818CF8) else Color(0x336366F1)
    val textColor = if (isDark) Color(0xFFE2E8F0) else Color(0xFF1E293B)

    Box(
        modifier = modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp),
        contentAlignment = Alignment.Center
    ) {
        Surface(
            shape = RoundedCornerShape(20.dp),
            color = bgColor,
            border = BorderStroke(1.dp, borderColor),
            tonalElevation = 4.dp,
            shadowElevation = 2.dp,
            modifier = Modifier.widthIn(max = 340.dp)
        ) {
            Row(
                modifier = Modifier
                    .padding(horizontal = 14.dp, vertical = 8.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.Center
            ) {
                if (isSecurityEvent) {
                    Surface(
                        shape = CircleShape,
                        color = iconColor.copy(alpha = 0.15f),
                        modifier = Modifier
                            .size(24.dp)
                            .padding(end = 4.dp)
                    ) {
                        Icon(
                            imageVector = icon,
                            contentDescription = "System Security Event",
                            tint = iconColor,
                            modifier = Modifier
                                .padding(4.dp)
                                .fillMaxSize()
                        )
                    }
                    Spacer(modifier = Modifier.width(8.dp))
                }

                Text(
                    text = text,
                    style = MaterialTheme.typography.labelMedium.copy(
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Medium,
                        letterSpacing = 0.2.sp
                    ),
                    color = textColor,
                    textAlign = TextAlign.Center
                )
            }
        }
    }
}

@Composable
fun DateDividerPill(
    dateText: String,
    modifier: Modifier = Modifier
) {
    val isDark = isAppInDarkTheme()
    val bgColor = if (isDark) Color(0x801F2937) else Color(0xB3E2E8F0)
    val textColor = if (isDark) Color(0xFF94A3B8) else Color(0xFF475569)

    Box(
        modifier = modifier
            .fillMaxWidth()
            .padding(vertical = 12.dp),
        contentAlignment = Alignment.Center
    ) {
        Surface(
            shape = CircleShape,
            color = bgColor,
            border = BorderStroke(0.5.dp, Color.White.copy(alpha = 0.2f)),
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 4.dp)
        ) {
            Text(
                text = dateText,
                style = MaterialTheme.typography.labelSmall.copy(
                    fontWeight = FontWeight.Bold,
                    fontSize = 10.sp
                ),
                color = textColor,
                modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp)
            )
        }
    }
}
