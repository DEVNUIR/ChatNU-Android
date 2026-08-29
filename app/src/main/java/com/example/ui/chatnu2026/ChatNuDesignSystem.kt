package com.example.ui.chatnu2026

import android.provider.Settings
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.remember
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.example.ui.theme.isAppInDarkTheme
import dev.chrisbanes.haze.HazeState
import dev.chrisbanes.haze.HazeTint
import dev.chrisbanes.haze.hazeChild

/**
 * ChatNU 2026 design tokens.
 *
 * The content layer stays inexpensive and readable. Real backdrop blur is reserved for the
 * functional layer: navigation, top bars, composer, menus and selected overlays. Chat/message
 * rows themselves remain normal content so scrolling performance is predictable.
 */
object ChatNuSpacing {
    val xxs = 2.dp
    val xs = 4.dp
    val sm = 8.dp
    val md = 12.dp
    val lg = 16.dp
    val xl = 20.dp
    val xxl = 24.dp
    val xxxl = 32.dp
}

object ChatNuRadius {
    val xs = 10.dp
    val sm = 14.dp
    val md = 18.dp
    val lg = 22.dp
    val xl = 28.dp
    val floating = 32.dp
    val pill = 100.dp
}

object ChatNuIconSize {
    val compact = 18.dp
    val standard = 22.dp
    val prominent = 26.dp
    val hero = 32.dp
}

object ChatNuAvatarSize {
    val compact = 32.dp
    val standard = 44.dp
    val conversation = 56.dp
    val profile = 88.dp
}

object ChatNuTouchTarget {
    val minimum = 48.dp
    val comfortable = 52.dp
}

object ChatNuDepth {
    val floating = 8.dp
    val overlay = 14.dp
}

object ChatNuGlass {
    const val lightAlpha = 0.76f
    const val darkAlpha = 0.66f
    const val accessibleAlpha = 0.94f
    val highlightAlpha = 0.42f
    val border = 1.dp
    val blurRadius = 24.dp
    const val noiseFactor = 0.08f
}

object ChatNuMotion {
    const val instantMs = 90
    const val quickMs = 150
    const val standardMs = 230
    const val emphasizedMs = 360

    val quickTween get() = tween<Float>(durationMillis = quickMs)
    val standardTween get() = tween<Float>(durationMillis = standardMs)

    fun <T> responsiveSpring() = spring<T>(
        dampingRatio = 0.78f,
        stiffness = Spring.StiffnessMediumLow
    )

    fun <T> expressiveSpring() = spring<T>(
        dampingRatio = 0.68f,
        stiffness = Spring.StiffnessLow
    )
}

/**
 * Screens opt into real backdrop blur by providing a HazeState around the content/overlay pair.
 * Keeping this nullable means standalone previews and old Android fallbacks remain simple.
 */
val LocalChatNuHazeState = staticCompositionLocalOf<HazeState?> { null }

@Immutable
data class ChatNuAccessibilityPreferences(
    val reduceMotion: Boolean,
    val increaseContrast: Boolean
)

@Composable
fun rememberChatNuAccessibilityPreferences(): ChatNuAccessibilityPreferences {
    val context = LocalContext.current
    return remember(context) {
        val resolver = context.contentResolver
        val animatorScale = runCatching {
            Settings.Global.getFloat(resolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f)
        }.getOrDefault(1f)
        val highContrast = runCatching {
            Settings.Secure.getInt(
                resolver,
                "high_text_contrast_enabled",
                0
            ) == 1
        }.getOrDefault(false)
        ChatNuAccessibilityPreferences(
            reduceMotion = animatorScale == 0f,
            increaseContrast = highContrast
        )
    }
}

@Composable
fun chatNuGlassColor(
    darkTheme: Boolean = isAppInDarkTheme(),
    increaseContrast: Boolean = rememberChatNuAccessibilityPreferences().increaseContrast
): Color {
    val alpha = when {
        increaseContrast -> ChatNuGlass.accessibleAlpha
        darkTheme -> ChatNuGlass.darkAlpha
        else -> ChatNuGlass.lightAlpha
    }
    return if (darkTheme) Color(0xFF151A23).copy(alpha = alpha)
    else Color(0xFFFFFEFC).copy(alpha = alpha)
}

@Composable
fun ChatNuGlassSurface(
    modifier: Modifier = Modifier,
    shape: RoundedCornerShape = RoundedCornerShape(ChatNuRadius.lg),
    elevation: Dp = ChatNuDepth.floating,
    contentPadding: PaddingValues = PaddingValues(0.dp),
    content: @Composable BoxScope.() -> Unit
) {
    // Important: use ChatNU's selected theme, not the phone's system theme. This keeps forced
    // light/dark mode internally consistent.
    val dark = isAppInDarkTheme()
    val accessibility = rememberChatNuAccessibilityPreferences()
    val base = chatNuGlassColor(dark, accessibility.increaseContrast)
    val hazeState = LocalChatNuHazeState.current
    val blurEnabled = hazeState != null && !accessibility.increaseContrast
    // Haze's style lambda is not composable, so capture theme values before entering it.
    val surfaceColor = MaterialTheme.colorScheme.surface
    val primaryColor = MaterialTheme.colorScheme.primary
    val borderBrush = Brush.linearGradient(
        listOf(
            Color.White.copy(alpha = if (dark) 0.20f else 0.76f),
            primaryColor.copy(alpha = 0.20f),
            Color.White.copy(alpha = if (dark) 0.05f else 0.24f)
        )
    )

    val glassModifier = if (blurEnabled) {
        modifier
            .shadow(elevation = elevation, shape = shape, clip = false)
            .clip(shape)
            .hazeChild(hazeState!!) {
                backgroundColor = surfaceColor
                tints = listOf(
                    HazeTint.Color(
                        if (dark) Color(0xFF111722).copy(alpha = 0.30f)
                        else Color.White.copy(alpha = 0.36f)
                    ),
                    HazeTint.Color(primaryColor.copy(alpha = 0.035f))
                )
                blurRadius = ChatNuGlass.blurRadius
                noiseFactor = ChatNuGlass.noiseFactor
                fallbackTint = HazeTint.Color(base.copy(alpha = 0.92f))
            }
            .border(BorderStroke(ChatNuGlass.border, borderBrush), shape)
    } else {
        modifier
            .shadow(elevation = elevation, shape = shape, clip = false)
            .border(BorderStroke(ChatNuGlass.border, borderBrush), shape)
    }

    Surface(
        modifier = glassModifier,
        shape = shape,
        // When a real backdrop is available, keep the surface itself light enough that the
        // background can actually be seen through the blur. High-contrast mode stays opaque.
        color = if (blurEnabled) {
            if (dark) Color(0xFF111722).copy(alpha = 0.28f)
            else Color.White.copy(alpha = 0.34f)
        } else base,
        contentColor = MaterialTheme.colorScheme.onSurface
    ) {
        Box(modifier = Modifier.padding(contentPadding), content = content)
    }
}

@Composable
fun ChatNuContentSurface(
    modifier: Modifier = Modifier,
    shape: RoundedCornerShape = RoundedCornerShape(ChatNuRadius.md),
    color: Color = MaterialTheme.colorScheme.surface,
    contentPadding: PaddingValues = PaddingValues(0.dp),
    content: @Composable BoxScope.() -> Unit
) {
    Surface(modifier = modifier, shape = shape, color = color) {
        Box(modifier = Modifier.padding(contentPadding), content = content)
    }
}

/** Semantic colors kept separate from status meaning so theme accents never imply delivery. */
object ChatNuSemantic {
    val Online = Color(0xFF2DA66E)
    val Warning = Color(0xFFE59A2E)
    val Error = Color(0xFFE0525B)
    val Read = Color(0xFF5B7CFF)
    val Secure = Color(0xFF2DA66E)
}
