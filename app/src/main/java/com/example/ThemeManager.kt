package com.example.ui.theme

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.graphics.Color

enum class ThemeMode {
    SYSTEM,
    LIGHT,
    DARK
}

enum class ThemePreset(
    val title: String,
    val primary: Color,
    val primaryLight: Color,
    val primaryDark: Color,
    val glassStart: Color,
    val glassEnd: Color
) {
    IOS_BLUE(
        title = "iOS Classic Blue",
        primary = Color(0xFF007AFF),
        primaryLight = Color(0xFF60A5FA),
        primaryDark = Color(0xFF1D4ED8),
        glassStart = Color(0xFF007AFF),
        glassEnd = Color(0xFF3B82F6)
    ),
    INDIGO_VIOLET(
        title = "Cyber Violet",
        primary = Color(0xFF6366F1),
        primaryLight = Color(0xFF818CF8),
        primaryDark = Color(0xFF4F46E5),
        glassStart = Color(0xFF6366F1),
        glassEnd = Color(0xFF8B5CF6)
    ),
    EMERALD_GREEN(
        title = "Emerald Mint",
        primary = Color(0xFF10B981),
        primaryLight = Color(0xFF34D399),
        primaryDark = Color(0xFF059669),
        glassStart = Color(0xFF10B981),
        glassEnd = Color(0xFF059669)
    ),
    SUNSET_ROSE(
        title = "Sunset Rose",
        primary = Color(0xFFFF2D55),
        primaryLight = Color(0xFFFB7185),
        primaryDark = Color(0xFFE11D48),
        glassStart = Color(0xFFFF2D55),
        glassEnd = Color(0xFFF43F5E)
    ),
    ELECTRIC_CYAN(
        title = "Electric Cyan",
        primary = Color(0xFF06B6D4),
        primaryLight = Color(0xFF38BDF8),
        primaryDark = Color(0xFF0891B2),
        glassStart = Color(0xFF06B6D4),
        glassEnd = Color(0xFF0284C7)
    )
}

object ThemeManager {
    var currentPreset by mutableStateOf(ThemePreset.IOS_BLUE)
    var themeMode by mutableStateOf(ThemeMode.DARK)
}

@Composable
fun isAppInDarkTheme(): Boolean {
    val systemDark = androidx.compose.foundation.isSystemInDarkTheme()
    return when (ThemeManager.themeMode) {
        ThemeMode.DARK -> true
        ThemeMode.LIGHT -> false
        ThemeMode.SYSTEM -> systemDark
    }
}
