import 'package:chatnu/app/chatnu_app.dart';
import 'package:chatnu/core/di/app_providers.dart';
import 'package:chatnu/core/glass/glass_components.dart';
import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:chatnu/core/theme/chatnu_tokens.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> useViewport(WidgetTester tester, Size size) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Widget demoApp() => ProviderScope(
    overrides: [appModeProvider.overrideWithValue(ChatNuAppMode.demo)],
    child: const ChatNuApp(),
  );

  testWidgets('shared interactive controls keep a 48dp minimum target', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ChatNuTheme.light,
          home: Scaffold(
            body: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                GlassButton(label: 'Continue', onPressed: () {}),
                GlassSegmentedControl<int>(
                  value: 0,
                  items: const <int, String>{0: 'All', 1: 'Unread'},
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byType(GlassButton)).height,
      greaterThanOrEqualTo(ChatNuSizing.minTouchTarget),
    );
    final segment = find.ancestor(
      of: find.text('All'),
      matching: find.byType(InkWell),
    );
    expect(
      tester.getSize(segment.first).height,
      greaterThanOrEqualTo(ChatNuSizing.minTouchTarget),
    );
  });

  testWidgets('GlassButton remains keyboard activatable', (tester) async {
    var activations = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: ChatNuTheme.light,
        home: Scaffold(
          body: GlassButton(
            label: 'Continue',
            onPressed: () => activations += 1,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(activations, 1);
  });

  testWidgets('desktop secondary click opens anchored conversation menu', (
    tester,
  ) async {
    await useViewport(tester, const Size(1440, 900));
    await tester.pumpWidget(demoApp());
    await tester.pumpAndSettle();

    final designTeam = find.text('Design team').first;
    await tester.tap(designTeam, buttons: kSecondaryMouseButton);
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate((widget) => widget is PopupMenuItem),
      findsNWidgets(2),
    );
    expect(find.byType(BottomSheet), findsNothing);
  });
}
