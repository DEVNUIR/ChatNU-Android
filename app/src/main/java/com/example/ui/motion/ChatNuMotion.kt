package com.example.ui.motion

import androidx.compose.animation.core.CubicBezierEasing
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween

/**
 * Original ChatNU motion tokens. They follow the ergonomic qualities of mature messengers:
 * immediate feedback, short continuity transitions, and subtle spring only on small controls.
 */
object ChatNuMotion {
    val standardEasing = CubicBezierEasing(0.2f, 0f, 0f, 1f)
    val emphasizedEasing = CubicBezierEasing(0.05f, 0.7f, 0.1f, 1f)

    val fastTween = tween<Float>(durationMillis = 160, easing = standardEasing)
    val messageEnter = tween<Float>(durationMillis = 220, easing = emphasizedEasing)

    val springyScale = spring<Float>(
        dampingRatio = 0.78f,
        stiffness = Spring.StiffnessMediumLow
    )

    val sheetSpring = spring<Float>(
        dampingRatio = Spring.DampingRatioNoBouncy,
        stiffness = Spring.StiffnessLow
    )
}
