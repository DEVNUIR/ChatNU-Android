import 'dart:async';

import 'package:chatnu/core/di/app_providers.dart';
import 'package:chatnu/core/glass/glass_components.dart';
import 'package:chatnu/core/glass/glass_surface.dart';
import 'package:chatnu/core/localization/chatnu_strings.dart';
import 'package:chatnu/core/realtime/chatnu_realtime_client.dart';
import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:chatnu/core/theme/chatnu_tokens.dart';
import 'package:chatnu/features/auth/application/session_controller.dart';
import 'package:chatnu/features/home/application/demo_messenger_controller.dart';
import 'package:chatnu/features/settings/application/appearance_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsPane extends ConsumerWidget {
  const SettingsPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(messengerDemoProvider);
    final session = ref.watch(sessionProvider);
    final endpoint = ref.watch(serverEndpointProvider);
    final appearance = ref.watch(appearanceProvider);
    final strings = ChatNuStrings.of(context);
    final palette = context.chatNu;
    final isDemo = ref.watch(appModeProvider) == ChatNuAppMode.demo;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: ChatNuSizing.contentMaxWidth),
          child: ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(
              ChatNuSpacing.md,
              ChatNuSpacing.sm,
              ChatNuSpacing.md,
              ChatNuSpacing.xl,
            ),
            children: <Widget>[
              GlassAppBar(
                title: Text(
                  strings.settings,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                subtitle: Text(
                  endpoint.hostLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: ChatNuSpacing.sm),
              _SettingsSection(
                title: strings.account,
                children: <Widget>[
                  ListTile(
                    leading: GlassAvatar(
                      label:
                          session.user?.displayName ?? state.currentUser.displayName,
                      imageUrl: session.user?.avatarUrl,
                    ),
                    title: Text(
                      session.user?.displayName ?? state.currentUser.displayName,
                    ),
                    subtitle: Text(
                      '@${session.user?.username ?? state.currentUser.username}',
                    ),
                  ),
                  if (session.offline)
                    ListTile(
                      leading: Icon(
                        Icons.cloud_off_outlined,
                        color: palette.warning,
                      ),
                      title: Text(strings.offlineSession),
                      subtitle: Text(strings.offlineSessionDetail),
                    ),
                ],
              ),
              const SizedBox(height: ChatNuSpacing.sm),
              _SettingsSection(
                title: strings.connection,
                children: <Widget>[
                  ListTile(
                    leading: Icon(_connectionIcon(state.realtimeStatus)),
                    title: Text(_connectionLabel(strings, state.realtimeStatus)),
                    subtitle: Text(endpoint.hostLabel),
                    trailing: IconButton(
                      tooltip: strings.refresh,
                      onPressed: isDemo
                          ? null
                          : () => unawaited(
                              ref
                                  .read(messengerDemoProvider.notifier)
                                  .refreshConversations(),
                            ),
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ),
                  if (endpoint.usesEmergencyTls)
                    ListTile(
                      leading: Icon(
                        Icons.security_outlined,
                        color: palette.warning,
                      ),
                      title: const Text('Emergency CA enrollment saved'),
                      subtitle: const Text(
                        'Flutter refuses this transport until native CA-pin verification reaches Android parity.',
                      ),
                    ),
                ],
              ),
              const SizedBox(height: ChatNuSpacing.sm),
              _SettingsSection(
                title: strings.appearance,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      ChatNuSpacing.md,
                      ChatNuSpacing.sm,
                      ChatNuSpacing.md,
                      ChatNuSpacing.xs,
                    ),
                    child: GlassSegmentedControl<ThemeMode>(
                      value: appearance.themeMode,
                      onChanged: (mode) => unawaited(
                        ref
                            .read(appearanceProvider.notifier)
                            .setThemeMode(mode),
                      ),
                      items: <ThemeMode, String>{
                        ThemeMode.system: strings.systemTheme,
                        ThemeMode.light: strings.lightTheme,
                        ThemeMode.dark: strings.darkTheme,
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      ChatNuSpacing.md,
                      ChatNuSpacing.xs,
                      ChatNuSpacing.md,
                      ChatNuSpacing.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          strings.glassQuality,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: ChatNuSpacing.xs),
                        GlassSegmentedControl<GlassEffectLevel>(
                          value: appearance.glassEffectLevel,
                          onChanged: (level) => unawaited(
                            ref
                                .read(appearanceProvider.notifier)
                                .setGlassEffectLevel(level),
                          ),
                          items: <GlassEffectLevel, String>{
                            GlassEffectLevel.full: strings.glassFull,
                            GlassEffectLevel.balanced: strings.glassBalanced,
                            GlassEffectLevel.reduced: strings.glassReduced,
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ChatNuSpacing.sm),
              _SettingsSection(
                title: strings.privacySecurity,
                children: <Widget>[
                  ListTile(
                    leading: Icon(
                      Icons.lock_outline_rounded,
                      color: palette.success,
                    ),
                    title: const Text('ChatNU Device Envelope v2'),
                    subtitle: const Text(
                      'Message payloads are encrypted on-device and content keys are wrapped independently for active member devices. This is ChatNU E2EE, not Signal Protocol.',
                    ),
                  ),
                  const ListTile(
                    leading: Icon(Icons.attach_file_rounded),
                    title: Text('Encrypted attachments'),
                    subtitle: Text(
                      'Attachment bytes are encrypted before upload. Decryption material travels inside the encrypted message payload.',
                    ),
                  ),
                ],
              ),
              if (!isDemo) ...<Widget>[
                const SizedBox(height: ChatNuSpacing.md),
                GlassButton(
                  label: strings.logout,
                  icon: Icons.logout_rounded,
                  destructive: true,
                  onPressed: () =>
                      unawaited(ref.read(sessionProvider.notifier).logout()),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static IconData _connectionIcon(RealtimeConnectionStatus status) =>
      switch (status) {
        RealtimeConnectionStatus.connected => Icons.cloud_done_outlined,
        RealtimeConnectionStatus.connecting => Icons.cloud_sync_outlined,
        RealtimeConnectionStatus.disconnected => Icons.cloud_off_outlined,
      };

  static String _connectionLabel(
    ChatNuStrings strings,
    RealtimeConnectionStatus status,
  ) => switch (status) {
    RealtimeConnectionStatus.connected => strings.realtimeConnected,
    RealtimeConnectionStatus.connecting => strings.realtimeConnecting,
    RealtimeConnectionStatus.disconnected => strings.realtimeDisconnected,
  };
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      variant: GlassVariant.weak,
      padding: const EdgeInsets.symmetric(vertical: ChatNuSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              ChatNuSpacing.md,
              ChatNuSpacing.sm,
              ChatNuSpacing.md,
              ChatNuSpacing.xs,
            ),
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          ...children,
        ],
      ),
    );
  }
}
