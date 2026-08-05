package com.devnu.chatnu.feature.onboarding

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.ArrowForward
import androidx.compose.material.icons.rounded.Hub
import androidx.compose.material.icons.rounded.Lock
import androidx.compose.material.icons.rounded.Router
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.devnu.chatnu.R
import com.devnu.chatnu.ui.components.AmbientBackdrop
import com.devnu.chatnu.ui.components.GlassSurface
import com.devnu.chatnu.ui.theme.AuroraBlue
import com.devnu.chatnu.ui.theme.ElectricViolet
import kotlin.math.cos
import kotlin.math.sin

@Composable
fun OnboardingScreen(viewModel: OnboardingViewModel, onContinue: () -> Unit) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    LaunchedEffect(state.identity?.userId) { if (state.identity != null) onContinue() }
    AmbientBackdrop {
        Column(
            Modifier.fillMaxSize().padding(horizontal = 24.dp).padding(top = 72.dp, bottom = 32.dp),
            verticalArrangement = Arrangement.SpaceBetween,
        ) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                Image(painterResource(R.drawable.ic_chatnu_logo), null, Modifier.size(42.dp))
                Column {
                    Text("ChatNU", style = MaterialTheme.typography.titleLarge)
                    Text("Private by architecture", style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
            Column(verticalArrangement = Arrangement.spacedBy(20.dp)) {
                MeshIllustration(Modifier.fillMaxWidth().height(if (state.showForm) 180.dp else 270.dp))
                Text("Messaging without a single point of failure.", style = MaterialTheme.typography.displayLarge)
                Text("Your identity belongs to you. Messages are stored locally and relayed through nodes you choose.", style = MaterialTheme.typography.bodyLarge, color = MaterialTheme.colorScheme.onSurfaceVariant)
                AnimatedVisibility(!state.showForm) {
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        FeatureChip(Icons.Rounded.Lock, "Local keys")
                        FeatureChip(Icons.Rounded.Router, "Node aware")
                        FeatureChip(Icons.Rounded.Hub, "Decentralized")
                    }
                }
                AnimatedVisibility(state.showForm) {
                    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                        OutlinedTextField(value = state.displayName, onValueChange = viewModel::updateDisplayName, modifier = Modifier.fillMaxWidth(), label = { Text("Display name") }, singleLine = true)
                        OutlinedTextField(value = state.username, onValueChange = viewModel::updateUsername, modifier = Modifier.fillMaxWidth(), label = { Text("Username") }, prefix = { Text("@") }, singleLine = true)
                        state.error?.let { Text(it, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodySmall) }
                    }
                }
            }
            Button(
                onClick = if (state.showForm) viewModel::createIdentity else viewModel::showForm,
                enabled = !state.creating,
                modifier = Modifier.fillMaxWidth().height(58.dp),
                shape = RoundedCornerShape(20.dp),
                colors = ButtonDefaults.buttonColors(containerColor = ElectricViolet),
            ) {
                if (state.creating) CircularProgressIndicator(Modifier.size(20.dp), strokeWidth = 2.dp, color = Color.White)
                else {
                    Text(if (state.showForm) "Generate local identity" else "Create local identity")
                    Spacer(Modifier.weight(1f))
                    Icon(Icons.Rounded.ArrowForward, null)
                }
            }
        }
    }
}

@Composable
private fun FeatureChip(icon: androidx.compose.ui.graphics.vector.ImageVector, text: String) {
    GlassSurface(shape = RoundedCornerShape(16.dp)) {
        Row(Modifier.padding(horizontal = 10.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            Icon(icon, null, Modifier.size(15.dp), tint = MaterialTheme.colorScheme.primary)
            Text(text, style = MaterialTheme.typography.labelMedium)
        }
    }
}

@Composable
private fun MeshIllustration(modifier: Modifier = Modifier) {
    val transition = rememberInfiniteTransition(label = "mesh")
    val phase by transition.animateFloat(0f, 360f, infiniteRepeatable(tween(9000), RepeatMode.Restart), label = "phase")
    Box(modifier, contentAlignment = Alignment.Center) {
        Box(Modifier.size(210.dp).background(ElectricViolet.copy(alpha = 0.10f), CircleShape))
        Canvas(Modifier.fillMaxSize()) {
            val center = Offset(size.width / 2, size.height / 2)
            val radius = size.minDimension * 0.34f
            val nodes = List(7) { index ->
                val angle = Math.toRadians((index * (360.0 / 7.0)) + phase * 0.12)
                Offset(center.x + cos(angle).toFloat() * radius, center.y + sin(angle).toFloat() * radius)
            }
            nodes.forEachIndexed { i, a -> nodes.drop(i + 1).forEach { b -> drawLine(Color.White.copy(alpha = 0.08f), a, b, strokeWidth = 1.3f) } }
            drawCircle(ElectricViolet.copy(alpha = 0.16f), radius = radius * 0.46f, center = center)
            drawCircle(ElectricViolet, radius = radius * 0.31f, center = center, style = Stroke(width = 4f))
            drawCircle(Color.White, radius = 8f, center = center)
            nodes.forEachIndexed { index, node ->
                drawCircle(if (index % 2 == 0) AuroraBlue else ElectricViolet, radius = 9f, center = node)
                drawCircle(Color.White.copy(alpha = 0.45f), radius = 14f, center = node, style = Stroke(2f))
            }
            drawArc(Color.White.copy(alpha = 0.18f), 210f, 110f, false, topLeft = Offset(center.x - radius * .58f, center.y - radius * .58f), size = androidx.compose.ui.geometry.Size(radius * 1.16f, radius * 1.16f), style = Stroke(3f, cap = StrokeCap.Round))
        }
    }
}
