package com.example.ui.theme

import android.content.Context
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
    CHATNU_NEON(
        title = "ChatNU Neon",
        primary = Color(0xFF1268FF),
        primaryLight = Color(0xFF22D3EE),
        primaryDark = Color(0xFF0754D8),
        glassStart = Color(0xFF1268FF),
        glassEnd = Color(0xFF22D3EE)
    ),
    IOS_BLUE(
        title = "Classic Blue",
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
    private const val PREFS = "chatnu_theme"
    private const val KEY_MODE = "mode"
    private const val KEY_PRESET = "preset"

    private var context: Context? = null

    var currentPreset by mutableStateOf(ThemePreset.CHATNU_NEON)
    var themeMode by mutableStateOf(ThemeMode.SYSTEM)

    fun initialize(appContext: Context) {
        context = appContext.applicationContext
        val prefs = context!!.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        themeMode = runCatching {
            ThemeMode.valueOf(prefs.getString(KEY_MODE, ThemeMode.SYSTEM.name) ?: ThemeMode.SYSTEM.name)
        }.getOrDefault(ThemeMode.SYSTEM)
        currentPreset = runCatching {
            ThemePreset.valueOf(
                prefs.getString(KEY_PRESET, ThemePreset.CHATNU_NEON.name)
                    ?: ThemePreset.CHATNU_NEON.name
            )
        }.getOrDefault(ThemePreset.CHATNU_NEON)
    }

    fun setMode(mode: ThemeMode) {
        themeMode = mode
        context?.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            ?.edit()?.putString(KEY_MODE, mode.name)?.apply()
    }

    fun setPreset(preset: ThemePreset) {
        currentPreset = preset
        context?.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            ?.edit()?.putString(KEY_PRESET, preset.name)?.apply()
    }
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
