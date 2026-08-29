package com.example.ui.theme

import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color

// ChatNU keeps indigo as its recognizable accent, but 2026 surfaces are calmer and more neutral.
val ChatNuAccent = Color(0xFF5B63E8)
val ChatNuAccentLight = Color(0xFF7C83F3)
val ChatNuAccentDark = Color(0xFF4850CF)

val ChatNuGlassAccentStart = Color(0xFF5B63E8)
val ChatNuGlassAccentEnd = Color(0xFF7B61D9)

// Deep neutral navy-charcoal: softer than pure black and better for layered translucent controls.
val ChatNuDarkBg = Color(0xFF0B0E14)
val ChatNuDarkSurface = Color(0xFF121720)
val ChatNuDarkCard = Color(0xFF1A202B)

// Warm-neutral light surfaces avoid the washed-out blue-gray look of the previous UI.
val ChatNuLightBg = Color(0xFFF8F7F4)
val ChatNuLightSurface = Color(0xFFFFFEFC)
val ChatNuLightCard = Color(0xFFF0EEE9)

val ChatNuEncryptedGreen = Color(0xFF2DA66E)
val ChatNuViewOnceOrange = Color(0xFFE59A2E)
val ChatNuDestructiveRed = Color(0xFFE0525B)

// Functional-layer translucency. These values are intentionally not used behind every message.
val GlassBorderLight = Color(0x66FFFFFF)
val GlassBorderDark = Color(0x2FFFFFFF)
val GlassSurfaceDark = Color(0xB8121720)
val GlassSurfaceLight = Color(0xD9FFFEFC)

val GlassBubbleOutgoingStart = Color(0xF05B63E8)
val GlassBubbleOutgoingEnd = Color(0xF06F65D9)
val GlassBubbleIncomingDark = Color(0xF01A202B)
val GlassBubbleIncomingLight = Color(0xF7FFFEFC)

val GlassSystemPillBg = Color(0xB30B0E14)
val GlassSystemPillBorder = Color(0x407C83F3)

val GlassLinearGradient = Brush.linearGradient(
    colors = listOf(
        Color(0x245B63E8),
        Color(0x107B61D9),
        Color.Transparent
    )
)
