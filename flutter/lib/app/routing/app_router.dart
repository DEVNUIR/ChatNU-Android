import 'package:chatnu/core/localization/chatnu_strings.dart';
import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:chatnu/features/home/application/demo_messenger_controller.dart';
import 'package:chatnu/features/home/presentation/messenger_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

abstract final class ChatNuRoutes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const home = '/home';
  static const chats = '/chats';
  static const contacts = '/contacts';
  static const profile = '/profile';
  static const settings = '/settings';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: ChatNuRoutes.chats,
    routes: <RouteBase>[
      GoRoute(path: ChatNuRoutes.home, redirect: (_, _) => ChatNuRoutes.chats),
      GoRoute(
        path: ChatNuRoutes.chats,
        builder: (_, _) => const MessengerShell(),
      ),
      GoRoute(
        path: '/conversation/:id',
        builder: (_, state) =>
            MessengerShell(initialConversationId: state.pathParameters['id']),
      ),
      GoRoute(
        path: ChatNuRoutes.contacts,
        builder: (_, _) =>
            const _DestinationRoute(destination: MessengerDestination.contacts),
      ),
      GoRoute(
        path: ChatNuRoutes.settings,
        builder: (_, _) =>
            const _DestinationRoute(destination: MessengerDestination.settings),
      ),
      GoRoute(
        path: ChatNuRoutes.splash,
        builder: (_, _) => const FeaturePlaceholderScreen(
          kind: PlaceholderKind.splash,
          icon: Icons.bolt_rounded,
        ),
      ),
      GoRoute(
        path: ChatNuRoutes.onboarding,
        builder: (_, _) => const FeaturePlaceholderScreen(
          kind: PlaceholderKind.onboarding,
          icon: Icons.explore_rounded,
        ),
      ),
      GoRoute(
        path: ChatNuRoutes.login,
        builder: (_, _) => const FeaturePlaceholderScreen(
          kind: PlaceholderKind.login,
          icon: Icons.lock_outline_rounded,
        ),
      ),
      GoRoute(
        path: ChatNuRoutes.profile,
        builder: (_, _) => const FeaturePlaceholderScreen(
          kind: PlaceholderKind.profile,
          icon: Icons.person_outline_rounded,
        ),
      ),
    ],
  );
});

class _DestinationRoute extends ConsumerStatefulWidget {
  const _DestinationRoute({required this.destination});

  final MessengerDestination destination;

  @override
  ConsumerState<_DestinationRoute> createState() => _DestinationRouteState();
}

class _DestinationRouteState extends ConsumerState<_DestinationRoute> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() {
      ref
          .read(messengerDemoProvider.notifier)
          .setDestination(widget.destination);
    });
  }

  @override
  Widget build(BuildContext context) => const MessengerShell();
}

enum PlaceholderKind { splash, onboarding, login, profile }

class FeaturePlaceholderScreen extends StatelessWidget {
  const FeaturePlaceholderScreen({
    required this.kind,
    required this.icon,
    super.key,
  });

  final PlaceholderKind kind;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    final strings = ChatNuStrings.of(context);
    final title = switch (kind) {
      PlaceholderKind.splash => strings.splash,
      PlaceholderKind.onboarding => strings.onboarding,
      PlaceholderKind.login => strings.login,
      PlaceholderKind.profile => strings.profile,
    };
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
              strings.routeSoon,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => context.go(ChatNuRoutes.chats),
              child: Text(strings.chats),
            ),
          ],
        ),
      ),
    );
  }
}
