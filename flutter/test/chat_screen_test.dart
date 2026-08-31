import 'package:chatnu/app/chatnu_app.dart';
import 'package:chatnu/core/di/app_providers.dart';
import 'package:flutter/material.dart';
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

  Future<void> pumpNavigation(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Widget demoApp() => ProviderScope(
    overrides: [appModeProvider.overrideWithValue(ChatNuAppMode.demo)],
    child: const ChatNuApp(),
  );

  testWidgets('desktop renders the messenger shell and sends in demo mode', (
    tester,
  ) async {
    await useViewport(tester, const Size(1440, 900));
    await tester.pumpWidget(demoApp());
    await tester.pumpAndSettle();

    expect(find.text('ChatNU'), findsOneWidget);
    expect(find.byTooltip('Chats'), findsOneWidget);
    expect(find.byTooltip('Contacts'), findsOneWidget);
    expect(find.byTooltip('Settings'), findsOneWidget);
    expect(find.byKey(const Key('conversation-list-compose')), findsOneWidget);
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

    expect(find.text('Hello from the messenger migration test'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone has three primary destinations and one compose action', (
    tester,
  ) async {
    await useViewport(tester, const Size(390, 844));
    await tester.pumpWidget(demoApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('conversation-list')), findsOneWidget);
    expect(find.byKey(const Key('message-composer-field')), findsNothing);
    expect(find.byKey(const Key('phone-nav-chats')), findsOneWidget);
    expect(find.byKey(const Key('phone-nav-contacts')), findsOneWidget);
    expect(find.byKey(const Key('phone-nav-settings')), findsOneWidget);
    expect(find.byKey(const Key('new-chat-fab')), findsOneWidget);
    expect(find.byKey(const Key('new-chat-bottom-button')), findsNothing);
    expect(find.byKey(const Key('conversation-list-compose')), findsNothing);

    await tester.tap(find.byKey(const Key('phone-nav-contacts')));
    await pumpNavigation(tester);

    expect(find.byKey(const Key('contact-search-field')), findsOneWidget);
    expect(find.textContaining('directory'), findsNothing);
    expect(find.byKey(const Key('new-chat-fab')), findsOneWidget);

    await tester.tap(find.byKey(const Key('phone-nav-chats')));
    await pumpNavigation(tester);
    await tester.tap(find.text('Leila Farhadi').first);
    await pumpNavigation(tester);

    expect(find.byKey(const Key('message-composer-field')), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);
    expect(find.byKey(const Key('new-chat-fab')), findsNothing);

    await tester.tap(find.byTooltip('Back'));
    await pumpNavigation(tester);

    expect(find.byKey(const Key('conversation-list')), findsOneWidget);
    expect(find.byKey(const Key('new-chat-fab')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings keeps technical protocol details behind Advanced', (
    tester,
  ) async {
    await useViewport(tester, const Size(430, 932));
    await tester.pumpWidget(demoApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('phone-nav-settings')));
    await pumpNavigation(tester);

    expect(find.text('Visual effects'), findsOneWidget);
    expect(find.textContaining('Signal Protocol'), findsNothing);
    expect(find.textContaining('SFU'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('End-to-end encryption'),
      280,
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('End-to-end encryption'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('settings-advanced')),
      280,
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('settings-advanced')), findsOneWidget);

    await tester.tap(find.byKey(const Key('settings-advanced')));
    await tester.pumpAndSettle();

    expect(find.text('ChatNU Device Envelope v2'), findsOneWidget);
    expect(find.textContaining('Signal Protocol'), findsOneWidget);
    expect(find.textContaining('SFU'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
