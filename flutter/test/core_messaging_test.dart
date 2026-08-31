import 'package:chatnu/app/chatnu_app.dart';
import 'package:chatnu/core/di/app_providers.dart';
import 'package:chatnu/features/home/application/demo_messenger_controller.dart';
import 'package:chatnu/features/messages/domain/message.dart';
import 'package:chatnu/features/messages/presentation/message_grouping.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MessageGrouping', () {
    ChatNuMessage message(
      String id,
      DateTime sentAt, {
      String senderId = 'alice',
      ChatNuMessageType type = ChatNuMessageType.text,
    }) {
      return ChatNuMessage(
        id: id,
        conversationId: 'conversation',
        senderId: senderId,
        senderName: senderId,
        body: id,
        sentAt: sentAt,
        type: type,
      );
    }

    test('groups same-sender messages within the five minute default', () {
      final start = DateTime(2026, 8, 30, 10);
      final messages = <ChatNuMessage>[
        message('one', start),
        message('two', start.add(const Duration(minutes: 3))),
        message('three', start.add(const Duration(minutes: 5))),
      ];

      expect(
        MessageGrouping.positionAt(messages, 0),
        MessageGroupPosition.first,
      );
      expect(
        MessageGrouping.positionAt(messages, 1),
        MessageGroupPosition.middle,
      );
      expect(
        MessageGrouping.positionAt(messages, 2),
        MessageGroupPosition.last,
      );
    });

    test('breaks groups across sender, day, system, or configured gap', () {
      final start = DateTime(2026, 8, 30, 23, 58);
      expect(
        MessageGrouping.canGroup(
          message('one', start),
          message('two', start.add(const Duration(minutes: 6))),
        ),
        isFalse,
      );
      expect(
        MessageGrouping.canGroup(
          message('one', start),
          message(
            'two',
            start.add(const Duration(minutes: 1)),
            senderId: 'bob',
          ),
        ),
        isFalse,
      );
      expect(
        MessageGrouping.canGroup(
          message('one', start),
          message(
            'system',
            start.add(const Duration(minutes: 1)),
            type: ChatNuMessageType.system,
          ),
        ),
        isFalse,
      );
      expect(
        MessageGrouping.canGroup(
          message('one', start),
          message('next-day', DateTime(2026, 8, 31, 0, 1)),
        ),
        isFalse,
      );
      expect(
        MessageGrouping.canGroup(
          message('one', start),
          message('two', start.add(const Duration(minutes: 2))),
          gap: const Duration(minutes: 1),
        ),
        isFalse,
      );
    });
  });

  testWidgets('in-chat search opens, finds decrypted messages, and closes', (
    tester,
  ) async {
    await _pumpDesktopDemo(tester);

    await tester.tap(
      find.byKey(const Key('conversation-in-chat-search-button')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('conversation-search-field')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('conversation-search-field')),
      'نسخه',
    );
    await tester.pumpAndSettle();

    expect(find.text('1/1'), findsOneWidget);
    expect(find.text('آره، نسخه جدید خیلی تمیزتر شده.'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('conversation-search-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('conversation-search-field')), findsNothing);
  });

  testWidgets('drafts survive switching between desktop conversations', (
    tester,
  ) async {
    await _pumpDesktopDemo(tester);

    final composer = find.byKey(const Key('message-composer-field'));
    await tester.enterText(composer, 'Draft for Leila');
    await tester.pump();

    await tester.tap(find.text('Design team'));
    await tester.pumpAndSettle();
    expect(_composerText(tester), isEmpty);

    await tester.enterText(composer, 'Draft for design');
    await tester.pump();

    await tester.tap(find.text('Leila Farhadi'));
    await tester.pumpAndSettle();
    expect(_composerText(tester), 'Draft for Leila');

    await tester.tap(find.text('Design team'));
    await tester.pumpAndSettle();
    expect(_composerText(tester), 'Draft for design');
    expect(tester.takeException(), isNull);
  });

  testWidgets('scroll-to-latest control appears when user leaves the bottom', (
    tester,
  ) async {
    await _pumpDesktopDemo(tester);
    final context = tester.element(find.byType(ChatNuApp));
    final container = ProviderScope.containerOf(context);
    final notifier = container.read(messengerDemoProvider.notifier);
    for (var index = 0; index < 28; index++) {
      notifier.sendText('direct-leila', 'Phase 1 filler message $index');
    }
    await tester.pumpAndSettle();

    final list = find.byKey(const Key('message-list'));
    final scrollable = find.descendant(
      of: list,
      matching: find.byType(Scrollable),
    );
    final scrollState = tester.state<ScrollableState>(scrollable);
    final target = scrollState.position.maxScrollExtent.clamp(220.0, 620.0);
    scrollState.position.jumpTo(target);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('scroll-to-latest-button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('scroll-to-latest-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('scroll-to-latest-button')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpDesktopDemo(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(1440, 900)
    ..devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appModeProvider.overrideWithValue(ChatNuAppMode.demo)],
      child: const ChatNuApp(),
    ),
  );
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('message-composer-field')), findsOneWidget);
}

String _composerText(WidgetTester tester) {
  final field = tester.widget<TextField>(
    find.byKey(const Key('message-composer-field')),
  );
  return field.controller?.text ?? '';
}
