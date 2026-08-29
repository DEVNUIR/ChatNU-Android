import 'package:chatnu/app/chatnu_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('desktop renders the real messenger shell and sends locally', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1440, 900)
      ..devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const ProviderScope(child: ChatNuApp()));
    await tester.pumpAndSettle();

    expect(find.text('ChatNU'), findsOneWidget);
    expect(find.byTooltip('Chats'), findsOneWidget);
    expect(find.byTooltip('Contacts'), findsOneWidget);
    expect(find.byTooltip('Settings'), findsOneWidget);
    expect(find.text('Leila Farhadi'), findsWidgets);
    expect(find.text('Design team'), findsOneWidget);
    expect(find.text('Nova 2'), findsNothing);
    expect(find.text('Models'), findsNothing);
    expect(find.byKey(const Key('message-composer-field')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('message-composer-field')),
      'Hello from the messenger migration test',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('message-send-button')));
    await tester.pumpAndSettle();

    expect(
      find.text('Hello from the messenger migration test'),
      findsWidgets,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone uses conversation list to chat navigation', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const ProviderScope(child: ChatNuApp()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('conversation-list')), findsOneWidget);
    expect(find.byKey(const Key('message-composer-field')), findsNothing);
    expect(find.text('Chats'), findsOneWidget);
    expect(find.text('Contacts'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.text('Leila Farhadi').first);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('message-composer-field')), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('conversation-list')), findsOneWidget);
    expect(find.byKey(const Key('message-composer-field')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
