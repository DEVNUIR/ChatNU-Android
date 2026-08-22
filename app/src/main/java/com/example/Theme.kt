package com.example.ui.theme

import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext

private val DarkColorScheme = darkColorScheme(
    primary = ChatNuAccent,
    secondary = ChatNuAccentLight,
    tertiary = ChatNuEncryptedGreen,
    background = ChatNuDarkBg,
    surface = ChatNuDarkSurface,
    surfaceVariant = ChatNuDarkCard,
    onPrimary = Color.White,
    onSecondary = Color.White,
    onBackground = Color(0xFFF1F5F9),
    onSurface = Color(0xFFF1F5F9)
)

private val LightColorScheme = lightColorScheme(
    primary = ChatNuAccent,
    secondary = ChatNuAccentDark,
    tertiary = ChatNuEncryptedGreen,
    background = ChatNuLightBg,
    surface = ChatNuLightSurface,
    surfaceVariant = ChatNuLightCard,
    onPrimary = Color.White,
    onSecondary = Color.White,
    onBackground = Color(0xFF0F172A),
    onSurface = Color(0xFF0F172A)
)

@Composable
fun MyApplicationTheme(
    darkTheme: Boolean = when (ThemeManager.themeMode) {
        ThemeMode.DARK -> true
        ThemeMode.LIGHT -> false
        ThemeMode.SYSTEM -> isSystemInDarkTheme()
    },
    dynamicColor: Boolean = false,
    content: @Composable () -> Unit
) {
    val activePreset = ThemeManager.currentPreset

    val darkScheme = darkColorScheme(
        primary = activePreset.primary,
        secondary = activePreset.primaryLight,
        tertiary = ChatNuEncryptedGreen,
        background = ChatNuDarkBg,
        surface = ChatNuDarkSurface,
        surfaceVariant = ChatNuDarkCard,
        onPrimary = Color.White,
        onSecondary = Color.White,
        onBackground = Color(0xFFF1F5F9),
        onSurface = Color(0xFFF1F5F9)
    )

    val lightScheme = lightColorScheme(
        primary = activePreset.primary,
        secondary = activePreset.primaryDark,
        tertiary = ChatNuEncryptedGreen,
        background = ChatNuLightBg,
        surface = ChatNuLightSurface,
        surfaceVariant = ChatNuLightCard,
        onPrimary = Color.White,
        onSecondary = Color.White,
        onBackground = Color(0xFF0F172A),
        onSurface = Color(0xFF0F172A)
    )

    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        }
        darkTheme -> darkScheme
        else -> lightScheme
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        content = content
    )
}

