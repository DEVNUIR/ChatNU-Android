package com.devnu.chatnu.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.devnu.chatnu.ui.theme.AuroraBlue
import com.devnu.chatnu.ui.theme.ElectricViolet

@Composable
fun AmbientBackdrop(modifier: Modifier = Modifier, content: @Composable () -> Unit) {
    Box(modifier.fillMaxSize().background(Color(0xFF07080D))) {
        Box(
            Modifier
                .size(280.dp)
                .offset(x = (-110).dp, y = (-90).dp)
                .blur(90.dp)
                .background(ElectricViolet.copy(alpha = 0.34f), CircleShape),
        )
        Box(
            Modifier
                .size(240.dp)
                .offset(x = 250.dp, y = 360.dp)
                .blur(100.dp)
                .background(AuroraBlue.copy(alpha = 0.20f), CircleShape),
        )
        Box(
            Modifier
                .fillMaxSize()
                .background(Brush.verticalGradient(listOf(Color.Transparent, Color(0xCC07080D), Color(0xFF07080D)))),
        )
        content()
    }
}
