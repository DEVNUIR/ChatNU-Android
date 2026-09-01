import 'dart:ui' as ui;

import 'package:chatnu/core/di/app_providers.dart';
import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:chatnu/features/home/presentation/messenger_shell.dart';
import 'package:chatnu/shared/widgets/chatnu_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('premium theme uses bundled bilingual typography', () {
    final style = ChatNuTheme.light.textTheme.bodyMedium;

    expect(style?.fontFamily, 'Manrope');
    expect(style?.fontFamilyFallback, contains('NotoSansArabic'));
  });

  testWidgets('ChatNU mark renders the canonical launcher artwork', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ChatNuTheme.light,
        home: const Center(child: ChatNuMark()),
      ),
    );
    await tester.pumpAndSettle();

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<AssetImage>());
    expect(
      (image.image as AssetImage).assetName,
      'assets/brand/chatnu_launcher.png',
    );
    expect(tester.takeException(), isNull);
  });

  test(
    'bundled launcher and fonts contain complete decodable binaries',
    () async {
      final launcher = await rootBundle.load(
        'assets/brand/chatnu_launcher.png',
      );
      expect(launcher.lengthInBytes, greaterThan(300000));
      final codec = await ui.instantiateImageCodec(
        launcher.buffer.asUint8List(
          launcher.offsetInBytes,
          launcher.lengthInBytes,
        ),
      );
      final frame = await codec.getNextFrame();
      expect(frame.image.width, 1024);
      expect(frame.image.height, 1024);
      frame.image.dispose();
      codec.dispose();

      const fontPaths = <String>[
        'assets/fonts/Manrope-400.ttf',
        'assets/fonts/Manrope-500.ttf',
        'assets/fonts/Manrope-600.ttf',
        'assets/fonts/Manrope-700.ttf',
        'assets/fonts/Manrope-800.ttf',
        'assets/fonts/NotoSansArabic-400.ttf',
        'assets/fonts/NotoSansArabic-500.ttf',
        'assets/fonts/NotoSansArabic-600.ttf',
        'assets/fonts/NotoSansArabic-700.ttf',
      ];
      for (final path in fontPaths) {
        final font = await rootBundle.load(path);
        final bytes = font.buffer.asUint8List(
          font.offsetInBytes,
          font.lengthInBytes,
        );
        expect(font.lengthInBytes, greaterThan(80000), reason: path);
        expect(bytes.take(4).toList(), <int>[0, 1, 0, 0], reason: path);
      }

      final manrope = FontLoader('ChatNuManropeIntegrity')
        ..addFont(rootBundle.load('assets/fonts/Manrope-400.ttf'));
      final arabic = FontLoader('ChatNuArabicIntegrity')
        ..addFont(rootBundle.load('assets/fonts/NotoSansArabic-400.ttf'));
      await Future.wait(<Future<void>>[manrope.load(), arabic.load()]);
    },
  );

  test('theme text colors keep readable contrast on every surface', () {
    double contrast(Color foreground, Color background) {
      final lighter =
          foreground.computeLuminance() > background.computeLuminance()
          ? foreground.computeLuminance()
          : background.computeLuminance();
      final darker =
          foreground.computeLuminance() > background.computeLuminance()
          ? background.computeLuminance()
          : foreground.computeLuminance();
      return (lighter + 0.05) / (darker + 0.05);
    }

    for (final palette in <ChatNuPalette>[
      ChatNuPalette.light,
      ChatNuPalette.dark,
    ]) {
      expect(
        contrast(palette.textPrimary, palette.backgroundPrimary),
        greaterThanOrEqualTo(7),
      );
      expect(
        contrast(palette.textSecondary, palette.backgroundElevated),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(palette.textMuted, palette.backgroundElevated),
        greaterThanOrEqualTo(3),
      );
    }
  });

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

    expect(find.text('گفت‌وگوها'), findsWidgets);
    expect(find.byKey(const Key('conversation-list')), findsOneWidget);
    expect(find.byKey(const Key('phone-nav-chats')), findsOneWidget);
    expect(find.byKey(const Key('new-chat-fab')), findsOneWidget);
    expect(find.text('Nova 2'), findsNothing);
    expect(find.text('Models'), findsNothing);

    final context = tester.element(find.byKey(const Key('phone-nav-chats')));
    expect(Directionality.of(context), TextDirection.rtl);
    expect(tester.takeException(), isNull);
  });
}
