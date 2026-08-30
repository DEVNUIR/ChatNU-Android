import 'dart:io';

import 'package:chatnu/core/config/server_endpoint.dart';
import 'package:chatnu/core/crypto/device_e2ee.dart';
import 'package:chatnu/core/crypto/portable_identity_store.dart';
import 'package:chatnu/core/di/app_providers.dart';
import 'package:chatnu/core/network/api_models.dart';
import 'package:chatnu/core/network/chatnu_api_client.dart';
import 'package:chatnu/core/platform/chatnu_native_bridge.dart';
import 'package:chatnu/core/storage/credential_vault.dart';
import 'package:chatnu/core/storage/secret_store.dart';
import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:chatnu/features/accounts/domain/chatnu_user.dart';
import 'package:chatnu/features/conversations/domain/conversation.dart';
import 'package:chatnu/features/home/data/messenger_local_store.dart';
import 'package:chatnu/features/home/data/messenger_repository.dart';
import 'package:chatnu/features/home/presentation/messenger_shell.dart';
import 'package:chatnu/features/messages/domain/message.dart';
import 'package:chatnu/features/messages/presentation/widgets/message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  group('local messenger cache', () {
    late Directory directory;
    late String databasePath;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('chatnu-cache-test-');
      databasePath =
          '${directory.path}${Platform.pathSeparator}messenger.sqlite';
    });

    tearDown(() async {
      if (await directory.exists()) await directory.delete(recursive: true);
    });

    test(
      'app restart restores cached messages, draft, cursor, and send state',
      () async {
        final first = _testStore(databasePath);
        const scope = 'https://chat.example:443|user-1';
        final conversation = _conversation('chat-1');
        final failed = _message(
          id: 'client-1',
          clientId: 'client-1',
          conversationId: conversation.id,
          minute: 12,
          deliveryState: MessageDeliveryState.failed,
        );

        await first.replaceConversations(scope, <ChatNuConversation>[
          conversation,
        ]);
        await first.upsertMessages(scope, <ChatNuMessage>[failed]);
        await first.saveDraft(scope, conversation.id, 'unfinished thought');
        await first.savePagination(
          scope,
          conversation.id,
          CachedConversationPage(hasMore: true, oldestLoadedAt: failed.sentAt),
        );
        await first.saveSyncCursor(scope, '2026-08-30T10:12:00.000Z');
        await first.close();

        final reopened = _testStore(databasePath);
        final snapshot = await reopened.readSnapshot(scope);

        expect(snapshot.conversations.single.id, conversation.id);
        expect(snapshot.messagesByConversation[conversation.id], hasLength(1));
        expect(
          snapshot
              .messagesByConversation[conversation.id]!
              .single
              .deliveryState,
          MessageDeliveryState.failed,
        );
        expect(snapshot.drafts[conversation.id], 'unfinished thought');
        expect(
          snapshot.paginationByConversation[conversation.id]!.hasMore,
          isTrue,
        );
        expect(snapshot.syncCursor, '2026-08-30T10:12:00.000Z');
        await reopened.close();
      },
    );

    test('offline cache remains readable without a remote request', () async {
      final store = _testStore(databasePath);
      const scope = 'https://chat.example:443|user-1';
      final conversation = _conversation('offline-chat');
      final message = _message(
        id: 'cached-message',
        conversationId: conversation.id,
        minute: 8,
      );
      await store.replaceConversations(scope, <ChatNuConversation>[
        conversation,
      ]);
      await store.upsertMessages(scope, <ChatNuMessage>[message]);

      final snapshot = await store.readSnapshot(scope);

      expect(snapshot.conversations.single.title, 'Conversation offline-chat');
      expect(
        snapshot.messagesByConversation[conversation.id]!.single.id,
        'cached-message',
      );
      await store.close();
    });
  });

  group('message merging and pagination', () {
    test('duplicate realtime events merge once', () {
      final message = _message(
        id: 'server-1',
        clientId: 'client-1',
        conversationId: 'chat',
        minute: 4,
      );

      final merged = mergeMessageLists(
        <ChatNuMessage>[message],
        <ChatNuMessage>[message, message],
      );

      expect(merged, hasLength(1));
      expect(merged.single.id, 'server-1');
    });

    test(
      'failed retry keeps stable client identity instead of duplicating',
      () {
        final failed = _message(
          id: 'client-7',
          clientId: 'client-7',
          conversationId: 'chat',
          minute: 4,
          deliveryState: MessageDeliveryState.failed,
        );
        final retried = _message(
          id: 'client-7',
          clientId: 'client-7',
          conversationId: 'chat',
          minute: 5,
          deliveryState: MessageDeliveryState.sending,
        );

        final merged = mergeMessageLists(
          <ChatNuMessage>[failed],
          <ChatNuMessage>[retried],
        );

        expect(merged, hasLength(1));
        expect(merged.single.deliveryState, MessageDeliveryState.sending);
      },
    );

    test('prepending older history preserves reverse-list anchor indices', () {
      final existing = <ChatNuMessage>[
        for (var minute = 10; minute < 15; minute += 1)
          _message(id: 'm$minute', conversationId: 'chat', minute: minute),
      ];
      final oldReverseIndices = <String, int>{
        for (var index = 0; index < existing.length; index += 1)
          existing[index].id: existing.length - 1 - index,
      };
      final older = <ChatNuMessage>[
        for (var minute = 5; minute < 10; minute += 1)
          _message(id: 'm$minute', conversationId: 'chat', minute: minute),
      ];

      final merged = mergeMessageLists(existing, older);

      for (final message in existing) {
        final chronologicalIndex = merged.indexWhere(
          (item) => item.id == message.id,
        );
        final reverseIndex = merged.length - 1 - chronologicalIndex;
        expect(reverseIndex, oldReverseIndices[message.id]);
      }
    });
  });

  test(
    'repository paginates beyond the initial page without replacing history',
    () async {
      final fixture = await _repositoryFixture();
      addTearDown(fixture.dispose);
      final initial = <MessageDto>[
        for (
          var index = 0;
          index < MessengerRepository.messagePageSize;
          index += 1
        )
          _dto('new-$index', DateTime.utc(2026, 8, 30, 11, index)),
      ];
      final older = <MessageDto>[
        _dto('old-1', DateTime.utc(2026, 8, 30, 9, 58)),
        _dto('old-2', DateTime.utc(2026, 8, 30, 9, 59)),
      ];
      fixture.api.messagePages.add(initial);
      fixture.api.messagePages.add(older);

      final first = await fixture.repository.loadInitialMessages('chat');
      final second = await fixture.repository.loadOlderMessages('chat');
      final cached = await fixture.store.readMessages(fixture.scope, 'chat');

      expect(first.messages, hasLength(MessengerRepository.messagePageSize));
      expect(first.hasMore, isTrue);
      expect(second.messages, hasLength(2));
      expect(second.hasMore, isFalse);
      expect(cached, hasLength(MessengerRepository.messagePageSize + 2));
      expect(cached.first.id, 'old-1');
    },
  );

  test(
    'reconnect catch-up resumes from persisted cursor and deduplicates events',
    () async {
      final fixture = await _repositoryFixture();
      addTearDown(fixture.dispose);
      final firstCursor = DateTime.utc(2026, 8, 30, 10).toIso8601String();
      final secondCursor = DateTime.utc(2026, 8, 30, 10, 1).toIso8601String();
      final message1 = _dto('sync-1', DateTime.utc(2026, 8, 30, 10));
      final message2 = _dto('sync-2', DateTime.utc(2026, 8, 30, 10, 1));
      fixture.api.syncPages.add(
        SyncResponse(
          events: <SyncEventDto>[
            SyncEventDto(type: 'message.created', message: message1),
          ],
          nextCursor: firstCursor,
        ),
      );
      fixture.api.syncPages.add(
        SyncResponse(
          events: <SyncEventDto>[
            SyncEventDto(type: 'message.created', message: message1),
            SyncEventDto(type: 'message.created', message: message2),
          ],
          nextCursor: secondCursor,
        ),
      );

      await fixture.repository.catchUp();
      await fixture.repository.catchUp();
      final snapshot = await fixture.store.readSnapshot(fixture.scope);

      expect(fixture.api.syncCursors, <String?>[null, firstCursor]);
      expect(snapshot.messagesByConversation['chat'], hasLength(2));
      expect(snapshot.syncCursor, secondCursor);
    },
  );

  testWidgets('delivery indicator never invents delivered/read double checks', (
    tester,
  ) async {
    for (final state in <MessageDeliveryState>[
      MessageDeliveryState.sentToServer,
      MessageDeliveryState.deliveredToRecipientDevice,
      MessageDeliveryState.read,
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: ChatNuTheme.light,
          home: Scaffold(body: DeliveryStatus(state: state)),
        ),
      );
      expect(find.byIcon(Icons.done_rounded), findsOneWidget);
      expect(find.byIcon(Icons.done_all_rounded), findsNothing);
      expect(find.byTooltip('Sent to server'), findsOneWidget);
    }

    await tester.pumpWidget(
      MaterialApp(
        theme: ChatNuTheme.light,
        home: const Scaffold(
          body: DeliveryStatus(state: MessageDeliveryState.queuedOffline),
        ),
      ),
    );
    expect(find.byTooltip('Queued'), findsOneWidget);
  });

  testWidgets('draft text is preserved separately while switching chats', (
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
        overrides: <Override>[
          appModeProvider.overrideWithValue(ChatNuAppMode.demo),
        ],
        child: MaterialApp(
          theme: ChatNuTheme.light,
          home: const MessengerShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Leila Farhadi').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('message-composer-field')),
      'Leila draft',
    );
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Navid Moradi').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('message-composer-field')),
      'Navid draft',
    );
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Leila Farhadi').first);
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(
      find.byKey(const Key('message-composer-field')),
    );
    expect(field.controller!.text, 'Leila draft');
  });
}

SqliteMessengerLocalStore _testStore(String path) => SqliteMessengerLocalStore(
  databaseFactory: databaseFactoryFfi,
  databasePath: () async => path,
);

ChatNuConversation _conversation(String id) => ChatNuConversation(
  id: id,
  title: 'Conversation $id',
  kind: ConversationKind.direct,
  members: const <ChatNuUser>[
    ChatNuUser(id: 'user-1', username: 'me', displayName: 'Me'),
    ChatNuUser(id: 'user-2', username: 'friend', displayName: 'Friend'),
  ],
  lastMessagePreview: 'Cached message',
  lastActivityAt: DateTime.utc(2026, 8, 30, 10),
);

ChatNuMessage _message({
  required String id,
  required String conversationId,
  required int minute,
  String? clientId,
  MessageDeliveryState deliveryState = MessageDeliveryState.sentToServer,
}) => ChatNuMessage(
  id: id,
  clientId: clientId,
  conversationId: conversationId,
  senderId: 'user-1',
  senderName: 'Me',
  body: id,
  sentAt: DateTime.utc(2026, 8, 30, 10, minute),
  deliveryState: deliveryState,
);

MessageDto _dto(String id, DateTime createdAt) => MessageDto(
  id: id,
  clientId: 'client-$id',
  conversationId: 'chat',
  senderId: 'user-2',
  senderName: 'Friend',
  type: 'TEXT',
  ciphertext: 'opaque-test-ciphertext',
  createdAt: createdAt.toIso8601String(),
  protocolVersion: 'legacy-test-protocol',
);

Future<_RepositoryFixture> _repositoryFixture() async {
  final directory = await Directory.systemTemp.createTemp(
    'chatnu-repository-test-',
  );
  final path = '${directory.path}${Platform.pathSeparator}messenger.sqlite';
  final store = _testStore(path);
  final secretStore = MemorySecretStore();
  final bridge = ChatNuNativeBridge();
  final vault = CredentialVault(store: secretStore, bridge: bridge);
  await vault.persist(
    const StoredSession(
      accessToken: 'access',
      refreshToken: 'refresh',
      deviceId: 'device-1',
      cryptoAccount: 'test-account',
      user: ChatNuUser(id: 'user-1', username: 'me', displayName: 'Me'),
    ),
  );
  final endpoint = ChatNuServerEndpoint.production();
  final api = _FakeApiClient(endpoint: endpoint, vault: vault);
  final e2ee = DeviceE2ee(
    portableIdentities: PortableIdentityStore(secretStore),
    nativeBridge: bridge,
  );
  final repository = MessengerRepository(
    api: api,
    e2ee: e2ee,
    vault: vault,
    localStore: store,
  );
  return _RepositoryFixture(
    directory: directory,
    store: store,
    api: api,
    repository: repository,
    scope: '${endpoint.identityNamespace}|user-1',
  );
}

class _RepositoryFixture {
  const _RepositoryFixture({
    required this.directory,
    required this.store,
    required this.api,
    required this.repository,
    required this.scope,
  });

  final Directory directory;
  final SqliteMessengerLocalStore store;
  final _FakeApiClient api;
  final MessengerRepository repository;
  final String scope;

  Future<void> dispose() async {
    await store.close();
    if (await directory.exists()) await directory.delete(recursive: true);
  }
}

class _FakeApiClient extends ChatNuApiClient {
  _FakeApiClient({
    required ChatNuServerEndpoint endpoint,
    required CredentialVault vault,
  }) : super(endpoint: endpoint, vault: vault);

  final List<List<MessageDto>> messagePages = <List<MessageDto>>[];
  final List<SyncResponse> syncPages = <SyncResponse>[];
  final List<String?> syncCursors = <String?>[];

  @override
  Future<List<MessageDto>> messages(
    String conversationId, {
    String? before,
    int limit = 100,
  }) async {
    if (messagePages.isEmpty) return const <MessageDto>[];
    return messagePages.removeAt(0);
  }

  @override
  Future<SyncResponse> sync({String? cursor, int limit = 500}) async {
    syncCursors.add(cursor);
    if (syncPages.isEmpty) {
      return SyncResponse(
        events: const <SyncEventDto>[],
        nextCursor: cursor ?? DateTime.utc(2026, 8, 30).toIso8601String(),
      );
    }
    return syncPages.removeAt(0);
  }
}
