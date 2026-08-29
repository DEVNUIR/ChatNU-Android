package com.example.ui.theme

import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Shapes
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.lerp
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp

private val ChatNuShapes = Shapes(
    extraSmall = RoundedCornerShape(8.dp),
    small = RoundedCornerShape(12.dp),
    medium = RoundedCornerShape(18.dp),
    large = RoundedCornerShape(24.dp),
    extraLarge = RoundedCornerShape(30.dp)
)

private fun darkSchemeFor(preset: ThemePreset) = darkColorScheme(
    primary = preset.primaryLight,
    onPrimary = Color(0xFF090A0F),
    primaryContainer = lerp(preset.primaryDark, ChatNuDarkSurface, 0.36f),
    onPrimaryContainer = Color(0xFFF4F3FF),
    secondary = lerp(preset.primaryLight, Color.White, 0.18f),
    onSecondary = Color(0xFF11131A),
    secondaryContainer = lerp(preset.primaryDark, ChatNuDarkCard, 0.64f),
    onSecondaryContainer = Color(0xFFE9E8F2),
    tertiary = ChatNuEncryptedGreen,
    onTertiary = Color(0xFF06140D),
    tertiaryContainer = Color(0xFF133A2A),
    onTertiaryContainer = Color(0xFFC3F1D7),
    error = Color(0xFFFFB4AB),
    errorContainer = Color(0xFF5A1B22),
    onErrorContainer = Color(0xFFFFDAD6),
    background = ChatNuDarkBg,
    onBackground = Color(0xFFF1F2F5),
    surface = ChatNuDarkSurface,
    onSurface = Color(0xFFF1F2F5),
    surfaceVariant = ChatNuDarkCard,
    onSurfaceVariant = Color(0xFFB9BEC8),
    outline = Color(0xFF858B96),
    outlineVariant = Color(0xFF363D49),
    surfaceDim = Color(0xFF090C12),
    surfaceBright = Color(0xFF262C36),
    surfaceContainerLowest = Color(0xFF080B10),
    surfaceContainerLow = Color(0xFF10151D),
    surfaceContainer = Color(0xFF151B24),
    surfaceContainerHigh = Color(0xFF1B222C),
    surfaceContainerHighest = Color(0xFF222A35)
)

private fun lightSchemeFor(preset: ThemePreset) = lightColorScheme(
    primary = preset.primary,
    onPrimary = Color.White,
    primaryContainer = lerp(preset.primaryLight, Color.White, 0.76f),
    onPrimaryContainer = lerp(preset.primaryDark, Color.Black, 0.16f),
    secondary = preset.primaryDark,
    onSecondary = Color.White,
    secondaryContainer = lerp(preset.primaryLight, ChatNuLightCard, 0.76f),
    onSecondaryContainer = Color(0xFF252632),
    tertiary = ChatNuEncryptedGreen,
    onTertiary = Color.White,
    tertiaryContainer = Color(0xFFD6F4E4),
    onTertiaryContainer = Color(0xFF0B4A31),
    error = ChatNuDestructiveRed,
    errorContainer = Color(0xFFFFDAD6),
    onErrorContainer = Color(0xFF5A161C),
    background = ChatNuLightBg,
    onBackground = Color(0xFF191B20),
    surface = ChatNuLightSurface,
    onSurface = Color(0xFF191B20),
    surfaceVariant = ChatNuLightCard,
    onSurfaceVariant = Color(0xFF5D6068),
    outline = Color(0xFF777A82),
    outlineVariant = Color(0xFFD4D0C8),
    surfaceDim = Color(0xFFE6E2DB),
    surfaceBright = Color(0xFFFFFEFC),
    surfaceContainerLowest = Color.White,
    surfaceContainerLow = Color(0xFFF5F3EF),
    surfaceContainer = Color(0xFFF0EEE9),
    surfaceContainerHigh = Color(0xFFEAE7E1),
    surfaceContainerHighest = Color(0xFFE4E1DA)
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
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        }
        darkTheme -> darkSchemeFor(activePreset)
        else -> lightSchemeFor(activePreset)
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        shapes = ChatNuShapes,
        content = content
    )
}
