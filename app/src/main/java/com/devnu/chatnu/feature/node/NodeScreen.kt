package com.devnu.chatnu.feature.node

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Add
import androidx.compose.material.icons.rounded.ArrowBackIosNew
import androidx.compose.material.icons.rounded.CheckCircle
import androidx.compose.material.icons.rounded.Hub
import androidx.compose.material.icons.rounded.Lock
import androidx.compose.material.icons.rounded.Speed
import androidx.compose.material.icons.rounded.Warning
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.devnu.chatnu.core.model.RelayNode
import com.devnu.chatnu.ui.components.AmbientBackdrop
import com.devnu.chatnu.ui.components.GlassSurface
import com.devnu.chatnu.ui.theme.ElectricViolet
import com.devnu.chatnu.ui.theme.SignalMint
import com.devnu.chatnu.ui.theme.WarningAmber

@Composable
fun NodeScreen(viewModel: NodeViewModel, onBack: () -> Unit) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    if (state.showAddDialog) {
        AlertDialog(
            onDismissRequest = { viewModel.showAddDialog(false) },
            title = { Text("Add relay node") },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text("ChatNU validates HTTPS, API compatibility and the realtime route before production use.")
                    OutlinedTextField(value = state.nodeHost, onValueChange = viewModel::updateHost, label = { Text("Node HTTPS URL") }, singleLine = true)
                    state.error?.let { Text(it, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodySmall) }
                }
            },
            confirmButton = { Button(onClick = viewModel::addNode, enabled = !state.saving) { Text(if (state.saving) "Checking…" else "Add node") } },
            dismissButton = { TextButton(onClick = { viewModel.showAddDialog(false) }) { Text("Cancel") } },
        )
    }
    AmbientBackdrop {
        LazyColumn(Modifier.fillMaxSize(), contentPadding = androidx.compose.foundation.layout.PaddingValues(top = 48.dp, bottom = 40.dp)) {
            item {
                Row(Modifier.fillMaxWidth().padding(horizontal = 8.dp), verticalAlignment = Alignment.CenterVertically) {
                    IconButton(onClick = onBack) { Icon(Icons.Rounded.ArrowBackIosNew, "Back") }
                    Column(Modifier.weight(1f)) {
                        Text("Relay nodes", style = MaterialTheme.typography.headlineMedium)
                        Text("Choose who carries your encrypted traffic", color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                    IconButton(onClick = { viewModel.showAddDialog(true) }) { Icon(Icons.Rounded.Add, "Add node") }
                }
                Spacer(Modifier.size(20.dp))
                NetworkSummary(state.nodes.firstOrNull { it.connected })
                Spacer(Modifier.size(20.dp))
                Text("Available nodes", style = MaterialTheme.typography.titleMedium, modifier = Modifier.padding(horizontal = 20.dp, vertical = 8.dp))
            }
            items(state.nodes, key = { it.id }) { node -> NodeCard(node) { viewModel.select(node.id) } }
        }
    }
}

@Composable
private fun NetworkSummary(connected: RelayNode?) {
    GlassSurface(Modifier.padding(horizontal = 20.dp).fillMaxWidth(), RoundedCornerShape(28.dp)) {
        Column(Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(Modifier.size(46.dp).clip(CircleShape).background(ElectricViolet.copy(alpha = .18f)), contentAlignment = Alignment.Center) { Icon(Icons.Rounded.Hub, null, tint = ElectricViolet) }
                Column(Modifier.padding(start = 12.dp)) {
                    Text(connected?.name ?: "Disconnected", style = MaterialTheme.typography.titleLarge)
                    Text(connected?.host ?: "Select a relay", style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                Metric(Icons.Rounded.Speed, "${connected?.latencyMs ?: 0} ms")
                Metric(Icons.Rounded.Lock, "Encrypted")
                Metric(Icons.Rounded.CheckCircle, if (connected?.trusted == true) "Trusted" else "Unverified")
            }
        }
    }
}

@Composable
private fun Metric(icon: androidx.compose.ui.graphics.vector.ImageVector, label: String) {
    Row(Modifier.clip(CircleShape).background(Color.White.copy(alpha = .06f)).padding(horizontal = 10.dp, vertical = 7.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(5.dp)) {
        Icon(icon, null, Modifier.size(14.dp), tint = SignalMint)
        Text(label, style = MaterialTheme.typography.labelMedium)
    }
}

@Composable
private fun NodeCard(node: RelayNode, onClick: () -> Unit) {
    GlassSurface(
        Modifier.padding(horizontal = 20.dp, vertical = 6.dp).fillMaxWidth().clickable(interactionSource = remember { MutableInteractionSource() }, indication = null, onClick = onClick),
        RoundedCornerShape(22.dp),
    ) {
        Row(Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
            Box(Modifier.size(42.dp).clip(CircleShape).background(if (node.connected) SignalMint.copy(alpha = .16f) else Color.White.copy(alpha = .06f)), contentAlignment = Alignment.Center) {
                Icon(Icons.Rounded.Hub, null, tint = if (node.connected) SignalMint else MaterialTheme.colorScheme.onSurfaceVariant)
            }
            Column(Modifier.weight(1f).padding(horizontal = 12.dp)) {
                Text(node.name, style = MaterialTheme.typography.titleMedium)
                Text("${node.region} · ${node.latencyMs} ms", style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                Text(node.host, style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            if (node.connected) Icon(Icons.Rounded.CheckCircle, null, tint = SignalMint)
            else if (!node.trusted) Icon(Icons.Rounded.Warning, null, tint = WarningAmber)
        }
    }
}
