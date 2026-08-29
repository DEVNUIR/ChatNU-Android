package com.example.ui.components

import androidx.compose.animation.core.*
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.dp

@Composable
fun ChatWallpaperCanvas(
    modifier: Modifier = Modifier,
    isDark: Boolean = isSystemInDarkTheme()
) {
    val infiniteTransition = rememberInfiniteTransition(label = "wallpaper_ambient")
    
    val orbPulse1 by infiniteTransition.animateFloat(
        initialValue = 0.8f,
        targetValue = 1.2f,
        animationSpec = infiniteRepeatable(
            animation = tween(8000, easing = LinearEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "orb1"
    )

    val orbPulse2 by infiniteTransition.animateFloat(
        initialValue = 1.1f,
        targetValue = 0.9f,
        animationSpec = infiniteRepeatable(
            animation = tween(11000, easing = LinearEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "orb2"
    )

    val bgColor = if (isDark) Color(0xFF090D16) else Color(0xFFF1F5F9)
    val gridColor = if (isDark) Color(0x0CFFFFFF) else Color(0x0C000000)
    val glow1 = if (isDark) Color(0x1F6366F1) else Color(0x156366F1)
    val glow2 = if (isDark) Color(0x1A8B5CF6) else Color(0x128B5CF6)
    val glow3 = if (isDark) Color(0x1010B981) else Color(0x0A10B981)
    val lineStrokeColor = if (isDark) Color(0x12818CF8) else Color(0x106366F1)

    Canvas(modifier = modifier.fillMaxSize()) {
        val width = size.width
        val height = size.height

        // Solid background
        drawRect(color = bgColor)

        // Floating ambient glowing orbs
        drawCircle(
            brush = Brush.radialGradient(
                colors = listOf(glow1, Color.Transparent),
                center = Offset(width * 0.2f, height * 0.25f),
                radius = width * 0.6f * orbPulse1
            ),
            center = Offset(width * 0.2f, height * 0.25f),
            radius = width * 0.6f * orbPulse1
        )

        drawCircle(
            brush = Brush.radialGradient(
                colors = listOf(glow2, Color.Transparent),
                center = Offset(width * 0.8f, height * 0.65f),
                radius = width * 0.75f * orbPulse2
            ),
            center = Offset(width * 0.8f, height * 0.65f),
            radius = width * 0.75f * orbPulse2
        )

        drawCircle(
            brush = Brush.radialGradient(
                colors = listOf(glow3, Color.Transparent),
                center = Offset(width * 0.4f, height * 0.85f),
                radius = width * 0.5f
            ),
            center = Offset(width * 0.4f, height * 0.85f),
            radius = width * 0.5f
        )

        // Subtle geometric grid pattern for glass background depth
        val gridSize = 40.dp.toPx()
        var x = 0f
        while (x < width) {
            drawLine(
                color = gridColor,
                start = Offset(x, 0f),
                end = Offset(x, height),
                strokeWidth = 1f
            )
            x += gridSize
        }

        var y = 0f
        while (y < height) {
            drawLine(
                color = gridColor,
                start = Offset(0f, y),
                end = Offset(width, y),
                strokeWidth = 1f
            )
            y += gridSize
        }

        // Modern abstract geometric line art
        val wavePath1 = Path().apply {
            moveTo(0f, height * 0.3f)
            cubicTo(
                width * 0.35f, height * 0.2f,
                width * 0.65f, height * 0.45f,
                width, height * 0.35f
            )
        }
        drawPath(
            path = wavePath1,
            color = lineStrokeColor,
            style = Stroke(width = 2.dp.toPx())
        )

        val wavePath2 = Path().apply {
            moveTo(0f, height * 0.7f)
            cubicTo(
                width * 0.4f, height * 0.8f,
                width * 0.7f, height * 0.6f,
                width, height * 0.75f
            )
        }
        drawPath(
            path = wavePath2,
            color = lineStrokeColor,
            style = Stroke(width = 1.5.dp.toPx())
        )
    }
}
