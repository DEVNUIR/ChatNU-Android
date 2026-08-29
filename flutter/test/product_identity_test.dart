import 'package:chatnu/core/di/app_providers.dart';
import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:chatnu/features/home/presentation/messenger_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Persian locale exposes RTL messenger navigation', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appModeProvider.overrideWithValue(ChatNuAppMode.demo)],
        child: MaterialApp(
          locale: const Locale('fa'),
          supportedLocales: const <Locale>[Locale('en'), Locale('fa')],
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ChatNuTheme.light,
          darkTheme: ChatNuTheme.dark,
          home: const MessengerShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('گفت‌وگوها'), findsOneWidget);
    expect(find.byKey(const Key('conversation-list')), findsOneWidget);
    expect(find.byKey(const Key('new-chat-bottom-button')), findsOneWidget);
    expect(find.text('Nova 2'), findsNothing);
    expect(find.text('Models'), findsNothing);

    final context = tester.element(find.text('گفت‌وگوها'));
    expect(Directionality.of(context), TextDirection.rtl);
    expect(tester.takeException(), isNull);
  });
}
