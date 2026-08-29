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
    // Keep enum identifiers stable for persisted preferences while modernizing their product names.
    CHATNU_NEON(
        title = "ChatNU Indigo",
        primary = Color(0xFF5B63E8),
        primaryLight = Color(0xFF7C83F3),
        primaryDark = Color(0xFF4850CF),
        glassStart = Color(0xFF5B63E8),
        glassEnd = Color(0xFF7B61D9)
    ),
    IOS_BLUE(
        title = "Ocean Blue",
        primary = Color(0xFF2979E8),
        primaryLight = Color(0xFF65A4F4),
        primaryDark = Color(0xFF1F5FBD),
        glassStart = Color(0xFF2979E8),
        glassEnd = Color(0xFF4B8CE6)
    ),
    INDIGO_VIOLET(
        title = "Soft Violet",
        primary = Color(0xFF7565C7),
        primaryLight = Color(0xFF9387D8),
        primaryDark = Color(0xFF5F50AA),
        glassStart = Color(0xFF7565C7),
        glassEnd = Color(0xFF8A6EC4)
    ),
    EMERALD_GREEN(
        title = "Emerald",
        primary = Color(0xFF2D9A72),
        primaryLight = Color(0xFF56B893),
        primaryDark = Color(0xFF217858),
        glassStart = Color(0xFF2D9A72),
        glassEnd = Color(0xFF3E8F72)
    ),
    SUNSET_ROSE(
        title = "Rose",
        primary = Color(0xFFD95472),
        primaryLight = Color(0xFFE68198),
        primaryDark = Color(0xFFB63E5B),
        glassStart = Color(0xFFD95472),
        glassEnd = Color(0xFFC95D7B)
    ),
    ELECTRIC_CYAN(
        title = "Coastal Cyan",
        primary = Color(0xFF278FA6),
        primaryLight = Color(0xFF58ACBD),
        primaryDark = Color(0xFF1E7184),
        glassStart = Color(0xFF278FA6),
        glassEnd = Color(0xFF39899A)
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
