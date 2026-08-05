package com.devnu.chatnu.ui.components

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import com.devnu.chatnu.ui.theme.AuroraBlue
import com.devnu.chatnu.ui.theme.ElectricViolet

@Composable
fun GlassSurface(
    modifier: Modifier = Modifier,
    shape: Shape = RoundedCornerShape(24.dp),
    content: @Composable () -> Unit,
) {
    Surface(
        modifier = modifier.border(BorderStroke(1.dp, Color.White.copy(alpha = 0.10f)), shape),
        shape = shape,
        color = MaterialTheme.colorScheme.surface.copy(alpha = 0.72f),
        tonalElevation = 0.dp,
        shadowElevation = 12.dp,
        content = content,
    )
}

@Composable
fun GradientAvatar(
    label: String,
    seed: Int,
    modifier: Modifier = Modifier,
    online: Boolean = false,
) {
    val palettes = listOf(
        listOf(ElectricViolet, AuroraBlue),
        listOf(Color(0xFFFF7A8A), Color(0xFFFFC46C)),
        listOf(Color(0xFF53E0C2), Color(0xFF2B8CFF)),
        listOf(Color(0xFFA36CFF), Color(0xFFFF6CAC)),
        listOf(Color(0xFFFFA95F), Color(0xFF7C5CFF)),
    )
    val palette = palettes[(seed.absoluteValue) % palettes.size]
    Box(modifier = modifier, contentAlignment = Alignment.BottomEnd) {
        Box(
            modifier = Modifier
                .matchParentSize()
                .clip(CircleShape)
                .background(Brush.linearGradient(palette)),
            contentAlignment = Alignment.Center,
        ) {
            Text(label.take(1).uppercase(), style = MaterialTheme.typography.titleMedium, color = Color.White)
        }
        if (online) {
            Box(
                Modifier
                    .padding(1.dp)
                    .clip(CircleShape)
                    .background(MaterialTheme.colorScheme.background)
                    .padding(2.dp)
                    .clip(CircleShape)
                    .background(Color(0xFF5FE1A2))
                    .padding(4.dp),
            )
        }
    }
}

@Composable
fun PillButton(
    icon: ImageVector,
    label: String,
    selected: Boolean = false,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val scale by animateFloatAsState(
        targetValue = if (selected) 1.02f else 1f,
        animationSpec = spring(dampingRatio = 0.72f, stiffness = 420f),
        label = "pillScale",
    )
    Row(
        modifier = modifier
            .graphicsLayer { scaleX = scale; scaleY = scale }
            .clip(RoundedCornerShape(18.dp))
            .background(if (selected) MaterialTheme.colorScheme.primary.copy(alpha = 0.18f) else Color.White.copy(alpha = 0.05f))
            .border(1.dp, if (selected) MaterialTheme.colorScheme.primary.copy(alpha = 0.35f) else Color.White.copy(alpha = 0.07f), RoundedCornerShape(18.dp))
            .clickable(interactionSource = remember { MutableInteractionSource() }, indication = null, onClick = onClick)
            .padding(horizontal = 14.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Icon(icon, contentDescription = null, tint = if (selected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant)
        Text(label, style = MaterialTheme.typography.labelLarge, color = if (selected) MaterialTheme.colorScheme.onSurface else MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

private val Int.absoluteValue: Int get() = if (this < 0) -this else this
