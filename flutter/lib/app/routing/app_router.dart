import 'package:chatnu/core/localization/chatnu_strings.dart';
import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:chatnu/features/auth/application/session_controller.dart';
import 'package:chatnu/features/auth/presentation/auth_screen.dart';
import 'package:chatnu/features/home/application/demo_messenger_controller.dart';
import 'package:chatnu/features/home/presentation/messenger_shell.dart';
import 'package:chatnu/shared/widgets/chatnu_mark.dart';
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

  // Compile-only aliases for retained Phase 1 prototype sources. The active
  // router does not expose AI history/model destinations.
  static const history = chats;
  static const models = contacts;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(sessionProvider);
  return GoRouter(
    initialLocation: ChatNuRoutes.splash,
    redirect: (_, state) {
      final location = state.matchedLocation;
      if (session.status == ChatNuSessionStatus.booting) {
        return location == ChatNuRoutes.splash ? null : ChatNuRoutes.splash;
      }
      if (!session.isAuthenticated) {
        return location == ChatNuRoutes.login ? null : ChatNuRoutes.login;
      }
      if (location == ChatNuRoutes.splash ||
          location == ChatNuRoutes.login ||
          location == ChatNuRoutes.onboarding ||
          location == ChatNuRoutes.home) {
        return ChatNuRoutes.chats;
      }
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: ChatNuRoutes.splash,
        builder: (_, _) => const _SplashScreen(),
      ),
      GoRoute(
        path: ChatNuRoutes.login,
        builder: (_, _) => const AuthScreen(),
      ),
      GoRoute(
        path: ChatNuRoutes.onboarding,
        redirect: (_, _) => ChatNuRoutes.login,
      ),
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
        path: ChatNuRoutes.profile,
        builder: (_, _) =>
            const _DestinationRoute(destination: MessengerDestination.settings),
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

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    final strings = ChatNuStrings.of(context);
    return Scaffold(
      backgroundColor: palette.backgroundPrimary,
      body: Center(
        child: Semantics(
          label: strings.splash,
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ChatNuMark(size: 64),
              SizedBox(height: 20),
              SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
