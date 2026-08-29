import 'package:chatnu/core/di/app_providers.dart';
import 'package:chatnu/core/storage/secret_store.dart';
import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:chatnu/features/auth/presentation/auth_screen.dart';
import 'package:chatnu/features/messages/domain/message.dart';
import 'package:chatnu/features/messages/presentation/widgets/message_bubble.dart';
import 'package:chatnu/features/settings/application/appearance_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Finder keyedTextField(String key) => find.byWidgetPredicate(
    (widget) => widget is TextField && widget.key == Key(key),
  );

  test('appearance controller persists theme selection', () async {
    final store = MemorySecretStore();
    final container = ProviderContainer(
      overrides: [secretStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    await Future<void>.delayed(Duration.zero);
    await container
        .read(appearanceProvider.notifier)
        .setThemeMode(ThemeMode.dark);

    expect(container.read(appearanceProvider).themeMode, ThemeMode.dark);
    expect(await store.read('chatnu.appearance.theme'), 'dark');
  });

  testWidgets('signup is a staged account flow', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [secretStoreProvider.overrideWithValue(MemorySecretStore())],
        child: MaterialApp(theme: ChatNuTheme.light, home: const AuthScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(keyedTextField('auth-username-field'), findsOneWidget);
    expect(keyedTextField('auth-password-field'), findsOneWidget);

    await tester.tap(find.byKey(const Key('auth-create-account')));
    await tester.pumpAndSettle();

    expect(find.text('Create your profile'), findsOneWidget);
    expect(keyedTextField('auth-display-name-field'), findsOneWidget);
    expect(keyedTextField('auth-password-field'), findsNothing);

    await tester.enterText(keyedTextField('auth-display-name-field'), 'Amir');
    await tester.enterText(keyedTextField('auth-username-field'), 'amir');
    await tester.tap(find.byKey(const Key('auth-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('Secure your account'), findsOneWidget);
    expect(keyedTextField('auth-password-field'), findsOneWidget);

    await tester.enterText(
      keyedTextField('auth-password-field'),
      'example-password',
    );
    await tester.tap(find.byKey(const Key('auth-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('Ready to join'), findsOneWidget);
    expect(find.text('Amir'), findsOneWidget);
    expect(find.text('@amir'), findsOneWidget);
  });

  testWidgets('failed outgoing text exposes retry without fake actions', (
    tester,
  ) async {
    final message = ChatNuMessage(
      id: 'failed-message',
      clientId: 'stable-client-id',
      conversationId: 'conversation-1',
      senderId: 'me',
      senderName: 'Me',
      body: 'Retry me',
      sentAt: DateTime(2026, 8, 29, 12),
      deliveryState: MessageDeliveryState.failed,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appModeProvider.overrideWithValue(ChatNuAppMode.demo)],
        child: MaterialApp(
          theme: ChatNuTheme.light,
          home: Scaffold(
            body: Center(
              child: MessageBubble(
                message: message,
                mine: true,
                showSender: false,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.longPress(find.text('Retry me'));
    await tester.pumpAndSettle();

    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Edit'), findsNothing);
    expect(find.text('Delete'), findsNothing);
    expect(find.text('Forward'), findsNothing);
    expect(find.text('Reply'), findsNothing);
  });
}
