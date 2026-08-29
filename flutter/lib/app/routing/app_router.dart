import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:chatnu/features/chat/presentation/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

abstract final class ChatNuRoutes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const home = '/home';
  static const chat = '/chat';
  static const history = '/history';
  static const models = '/models';
  static const profile = '/profile';
  static const settings = '/settings';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: ChatNuRoutes.chat,
    routes: <RouteBase>[
      GoRoute(path: ChatNuRoutes.home, redirect: (_, _) => ChatNuRoutes.chat),
      GoRoute(path: ChatNuRoutes.chat, builder: (_, _) => const ChatScreen()),
      GoRoute(
        path: '/conversation/:id',
        builder: (_, _) => const ChatScreen(),
      ),
      for (final route in <({String path, String title, IconData icon})>[
        (path: ChatNuRoutes.splash, title: 'Splash', icon: Icons.bolt_rounded),
        (path: ChatNuRoutes.onboarding, title: 'Onboarding', icon: Icons.explore_rounded),
        (path: ChatNuRoutes.login, title: 'Login', icon: Icons.lock_outline_rounded),
        (path: ChatNuRoutes.history, title: 'History', icon: Icons.history_rounded),
        (path: ChatNuRoutes.models, title: 'Models', icon: Icons.hub_outlined),
        (path: ChatNuRoutes.profile, title: 'Profile', icon: Icons.person_outline_rounded),
        (path: ChatNuRoutes.settings, title: 'Settings', icon: Icons.tune_rounded),
      ])
        GoRoute(
          path: route.path,
          builder: (_, _) => FeaturePlaceholderScreen(
            title: route.title,
            icon: route.icon,
          ),
        ),
    ],
  );
});

class FeaturePlaceholderScreen extends StatelessWidget {
  const FeaturePlaceholderScreen({
    required this.title,
    required this.icon,
    super.key,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    return Scaffold(
      backgroundColor: palette.backgroundPrimary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 36, color: palette.accentPrimary),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Route boundary ready for a later migration phase.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => context.go(ChatNuRoutes.chat),
              child: const Text('Back to chat'),
            ),
          ],
        ),
      ),
    );
  }
}
