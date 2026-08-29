import 'package:chatnu/app/routing/app_router.dart';
import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:chatnu/features/calls/presentation/call_overlay.dart';
import 'package:chatnu/features/settings/application/appearance_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatNuApp extends ConsumerWidget {
  const ChatNuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(
      appearanceProvider.select((value) => value.themeMode),
    );
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'ChatNU',
      theme: ChatNuTheme.light,
      darkTheme: ChatNuTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      supportedLocales: const <Locale>[Locale('en'), Locale('fa')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            child ?? const SizedBox.shrink(),
            const CallOverlay(),
          ],
        );
      },
    );
  }
}
