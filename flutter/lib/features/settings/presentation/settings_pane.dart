import 'dart:async';

import 'package:chatnu/core/di/app_providers.dart';
import 'package:chatnu/core/glass/glass_surface.dart';
import 'package:chatnu/core/realtime/chatnu_realtime_client.dart';
import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:chatnu/core/theme/chatnu_tokens.dart';
import 'package:chatnu/features/auth/application/session_controller.dart';
import 'package:chatnu/features/home/application/demo_messenger_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsPane extends ConsumerWidget {
  const SettingsPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(messengerDemoProvider);
    final session = ref.watch(sessionProvider);
    final endpoint = ref.watch(serverEndpointProvider);
    final themeMode = ref.watch(themeModeProvider);
    final palette = context.chatNu;
    final isDemo = ref.watch(appModeProvider) == ChatNuAppMode.demo;

    return ColoredBox(
      color: palette.backgroundPrimary,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(ChatNuSpacing.lg),
              children: <Widget>[
                Text(
                  'Settings',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: ChatNuSpacing.md),
                _SettingsSection(
                  title: 'Account',
                  children: <Widget>[
                    ListTile(
                      leading: const Icon(Icons.person_outline_rounded),
                      title: Text(session.user?.displayName ?? state.currentUser.displayName),
                      subtitle: Text('@${session.user?.username ?? state.currentUser.username}'),
                    ),
                    if (session.offline)
                      const ListTile(
                        leading: Icon(Icons.cloud_off_outlined),
                        title: Text('Offline session'),
                        subtitle: Text(
                          'Cached credentials are available, but the selected server could not be verified right now.',
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: ChatNuSpacing.sm),
                _SettingsSection(
                  title: 'Connection',
                  children: <Widget>[
                    ListTile(
                      leading: Icon(_connectionIcon(state.realtimeStatus)),
                      title: Text(_connectionLabel(state.realtimeStatus)),
                      subtitle: Text(endpoint.hostLabel),
                      trailing: IconButton(
                        tooltip: 'Refresh conversations',
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
                      const ListTile(
                        leading: Icon(Icons.security_outlined),
                        title: Text('Emergency CA enrollment saved'),
                        subtitle: Text(
                          'Flutter currently refuses this transport until native CA-pin verification has parity with the Android client.',
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: ChatNuSpacing.sm),
                _SettingsSection(
                  title: 'Appearance',
                  children: <Widget>[
                    RadioGroup<ThemeMode>(
                      groupValue: themeMode,
                      onChanged: (mode) {
                        if (mode != null) {
                          ref.read(themeModeProvider.notifier).setMode(mode);
                        }
                      },
                      child: const Column(
                        children: <Widget>[
                          RadioListTile<ThemeMode>(
                            value: ThemeMode.system,
                            title: Text('System'),
                          ),
                          RadioListTile<ThemeMode>(
                            value: ThemeMode.light,
                            title: Text('Light'),
                          ),
                          RadioListTile<ThemeMode>(
                            value: ThemeMode.dark,
                            title: Text('Dark'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: ChatNuSpacing.md),
                if (!isDemo)
                  OutlinedButton.icon(
                    key: const Key('logout-button'),
                    onPressed: () => unawaited(
                      ref.read(sessionProvider.notifier).logout(),
                    ),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Log out'),
                  ),
              ],
            ),
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

  static String _connectionLabel(RealtimeConnectionStatus status) =>
      switch (status) {
        RealtimeConnectionStatus.connected => 'Realtime connected',
        RealtimeConnectionStatus.connecting => 'Connecting realtime',
        RealtimeConnectionStatus.disconnected => 'Realtime disconnected',
      };
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      variant: GlassVariant.weak,
      borderRadius: ChatNuRadii.lg,
      padding: const EdgeInsets.symmetric(vertical: ChatNuSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              ChatNuSpacing.md,
              ChatNuSpacing.sm,
              ChatNuSpacing.md,
              ChatNuSpacing.xs,
            ),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
