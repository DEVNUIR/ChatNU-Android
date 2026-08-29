import 'package:chatnu/app/chatnu_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'desktop chat shell renders and accepts a local mock message',
    (tester) async {
      tester.view
        ..physicalSize = const Size(1440, 900)
        ..devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const ProviderScope(child: ChatNuApp()));
      await tester.pumpAndSettle();

      expect(find.text('ChatNU'), findsWidgets);
      expect(find.text('New chat'), findsOneWidget);
      expect(find.text('Nova 2'), findsWidgets);
      expect(find.byKey(const Key('chat-composer-field')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('chat-composer-field')),
        'Hello from the Phase 1 smoke test',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('chat-send-button')));
      await tester.pumpAndSettle();

      expect(find.text('Hello from the Phase 1 smoke test'), findsOneWidget);
    },
  );

  testWidgets('phone shell stays single column and opens mobile navigation', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const ProviderScope(child: ChatNuApp()));
    await tester.pumpAndSettle();

    expect(find.text('New chat'), findsNothing);
    expect(find.byTooltip('Navigation'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Navigation'));
    await tester.pumpAndSettle();

    expect(find.text('New chat'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
