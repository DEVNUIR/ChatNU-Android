import 'dart:convert';
import 'dart:io';

import 'package:chatnu/features/accounts/domain/chatnu_user.dart';
import 'package:chatnu/features/conversations/domain/conversation.dart';
import 'package:chatnu/features/messages/domain/message.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class CachedConversationPage {
  const CachedConversationPage({
    required this.hasMore,
    this.oldestLoadedAt,
  });

  final bool hasMore;
  final DateTime? oldestLoadedAt;
}

class MessengerCacheSnapshot {
  const MessengerCacheSnapshot({
    required this.conversations,
    required this.messagesByConversation,
    required this.drafts,
    required this.paginationByConversation,
    this.syncCursor,
  });

  final List<ChatNuConversation> conversations;
  final Map<String, List<ChatNuMessage>> messagesByConversation;
  final Map<String, String> drafts;
  final Map<String, CachedConversationPage> paginationByConversation;
  final String? syncCursor;
}

abstract class MessengerLocalStore {
  Future<MessengerCacheSnapshot> readSnapshot(String scope);

  Future<List<ChatNuMessage>> readMessages(String scope, String conversationId);

  Future<CachedConversationPage?> readPagination(
    String scope,
    String conversationId,
  );

  Future<String?> readSyncCursor(String scope);

  Future<void> replaceConversations(
    String scope,
    List<ChatNuConversation> conversations,
  );

  Future<void> upsertConversation(String scope, ChatNuConversation conversation);

  Future<void> upsertMessages(
    String scope,
    Iterable<ChatNuMessage> messages,
  );

  Future<void> replaceMessage(
    String scope,
    String conversationId,
    String oldId,
    ChatNuMessage replacement,
  );

  Future<void> saveDraft(String scope, String conversationId, String text);

  Future<void> savePagination(
    String scope,
    String conversationId,
    CachedConversationPage page,
  );

  Future<void> saveSyncCursor(String scope, String cursor);

  Future<void> close();
}

class SqliteMessengerLocalStore implements MessengerLocalStore {
  SqliteMessengerLocalStore({
    DatabaseFactory? databaseFactory,
    Future<String> Function()? databasePath,
  }) : _databaseFactory = databaseFactory ?? _platformDatabaseFactory(),
       _databasePath = databasePath ?? _platformDatabasePath;

  static bool _ffiInitialized = false;

  final DatabaseFactory _databaseFactory;
  final Future<String> Function() _databasePath;
  Future<Database>? _database;

  static DatabaseFactory _platformDatabaseFactory() {
    if (Platform.isLinux || Platform.isWindows) {
      if (!_ffiInitialized) {
        sqfliteFfiInit();
        _ffiInitialized = true;
      }
      return databaseFactoryFfi;
    }
    return databaseFactory;
  }

  static Future<String> _platformDatabasePath() async {
    if (Platform.isLinux || Platform.isWindows) {
      final directory = await getApplicationSupportDirectory();
      await directory.create(recursive: true);
      return '${directory.path}${Platform.pathSeparator}chatnu-messenger.sqlite';
    }
    final root = await getDatabasesPath();
    return '$root${Platform.pathSeparator}chatnu-messenger.sqlite';
  }

  Future<Database> get _db => _database ??= _open();

  Future<Database> _open() async {
    return _databaseFactory.openDatabase(
      await _databasePath(),
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (database) async {
          await database.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (database, _) async {
          await database.execute('''
CREATE TABLE conversations (
  scope TEXT NOT NULL,
  id TEXT NOT NULL,
  payload TEXT NOT NULL,
  PRIMARY KEY (scope, id)
)
''');
          await database.execute('''
CREATE TABLE messages (
  scope TEXT NOT NULL,
  conversation_id TEXT NOT NULL,
  id TEXT NOT NULL,
  client_id TEXT,
  sent_at INTEGER NOT NULL,
  payload TEXT NOT NULL,
  PRIMARY KEY (scope, id)
)
''');
          await database.execute('''
CREATE INDEX messages_by_conversation
ON messages (scope, conversation_id, sent_at, id)
''');
          await database.execute('''
CREATE INDEX messages_by_client
ON messages (scope, conversation_id, client_id)
''');
          await database.execute('''
CREATE TABLE drafts (
  scope TEXT NOT NULL,
  conversation_id TEXT NOT NULL,
  text TEXT NOT NULL,
  updated_at INTEGER NOT NULL,
  PRIMARY KEY (scope, conversation_id)
)
''');
          await database.execute('''
CREATE TABLE pagination (
  scope TEXT NOT NULL,
  conversation_id TEXT NOT NULL,
  oldest_loaded_at INTEGER,
  has_more INTEGER NOT NULL,
  PRIMARY KEY (scope, conversation_id)
)
''');
          await database.execute('''
CREATE TABLE sync_state (
  scope TEXT PRIMARY KEY,
  cursor TEXT NOT NULL
)
''');
        },
      ),
    );
  }

  @override
  Future<MessengerCacheSnapshot> readSnapshot(String scope) async {
    final database = await _db;
    final conversationRows = await database.query(
      'conversations',
      where: 'scope = ?',
      whereArgs: <Object?>[scope],
    );
    final messageRows = await database.query(
      'messages',
      where: 'scope = ?',
      whereArgs: <Object?>[scope],
      orderBy: 'sent_at ASC, id ASC',
    );
    final draftRows = await database.query(
      'drafts',
      where: 'scope = ?',
      whereArgs: <Object?>[scope],
    );
    final paginationRows = await database.query(
      'pagination',
      where: 'scope = ?',
      whereArgs: <Object?>[scope],
    );

    final messages = <String, List<ChatNuMessage>>{};
    for (final row in messageRows) {
      final message = _messageFromPayload(row['payload'] as String);
      messages.putIfAbsent(message.conversationId, () => <ChatNuMessage>[]).add(
        message,
      );
    }

    final drafts = <String, String>{};
    for (final row in draftRows) {
      drafts[row['conversation_id'] as String] = row['text'] as String;
    }

    final pagination = <String, CachedConversationPage>{};
    for (final row in paginationRows) {
      final millis = row['oldest_loaded_at'] as int?;
      pagination[row['conversation_id'] as String] = CachedConversationPage(
        hasMore: (row['has_more'] as int? ?? 0) == 1,
        oldestLoadedAt: millis == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true).toLocal(),
      );
    }

    return MessengerCacheSnapshot(
      conversations: conversationRows
          .map((row) => _conversationFromPayload(row['payload'] as String))
          .toList(growable: false),
      messagesByConversation: messages,
      drafts: drafts,
      paginationByConversation: pagination,
      syncCursor: await readSyncCursor(scope),
    );
  }

  @override
  Future<List<ChatNuMessage>> readMessages(
    String scope,
    String conversationId,
  ) async {
    final database = await _db;
    final rows = await database.query(
      'messages',
      where: 'scope = ? AND conversation_id = ?',
      whereArgs: <Object?>[scope, conversationId],
      orderBy: 'sent_at ASC, id ASC',
    );
    return rows
        .map((row) => _messageFromPayload(row['payload'] as String))
        .toList(growable: false);
  }

  @override
  Future<CachedConversationPage?> readPagination(
    String scope,
    String conversationId,
  ) async {
    final database = await _db;
    final rows = await database.query(
      'pagination',
      columns: const <String>['oldest_loaded_at', 'has_more'],
      where: 'scope = ? AND conversation_id = ?',
      whereArgs: <Object?>[scope, conversationId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final millis = rows.first['oldest_loaded_at'] as int?;
    return CachedConversationPage(
      hasMore: (rows.first['has_more'] as int? ?? 0) == 1,
      oldestLoadedAt: millis == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true).toLocal(),
    );
  }

  @override
  Future<String?> readSyncCursor(String scope) async {
    final database = await _db;
    final rows = await database.query(
      'sync_state',
      columns: const <String>['cursor'],
      where: 'scope = ?',
      whereArgs: <Object?>[scope],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['cursor'] as String;
  }

  @override
  Future<void> replaceConversations(
    String scope,
    List<ChatNuConversation> conversations,
  ) async {
    final database = await _db;
    await database.transaction((transaction) async {
      final keep = conversations.map((item) => item.id).toSet();
      final existing = await transaction.query(
        'conversations',
        columns: const <String>['id'],
        where: 'scope = ?',
        whereArgs: <Object?>[scope],
      );
      for (final row in existing) {
        final id = row['id'] as String;
        if (keep.contains(id)) continue;
        await transaction.delete(
          'conversations',
          where: 'scope = ? AND id = ?',
          whereArgs: <Object?>[scope, id],
        );
        await transaction.delete(
          'messages',
          where: 'scope = ? AND conversation_id = ?',
          whereArgs: <Object?>[scope, id],
        );
        await transaction.delete(
          'drafts',
          where: 'scope = ? AND conversation_id = ?',
          whereArgs: <Object?>[scope, id],
        );
        await transaction.delete(
          'pagination',
          where: 'scope = ? AND conversation_id = ?',
          whereArgs: <Object?>[scope, id],
        );
      }
      for (final conversation in conversations) {
        await _upsertConversation(transaction, scope, conversation);
      }
    });
  }

  @override
  Future<void> upsertConversation(
    String scope,
    ChatNuConversation conversation,
  ) async {
    await _upsertConversation(await _db, scope, conversation);
  }

  Future<void> _upsertConversation(
    DatabaseExecutor executor,
    String scope,
    ChatNuConversation conversation,
  ) async {
    await executor.insert('conversations', <String, Object?>{
      'scope': scope,
      'id': conversation.id,
      'payload': jsonEncode(_conversationToJson(conversation)),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> upsertMessages(
    String scope,
    Iterable<ChatNuMessage> messages,
  ) async {
    final database = await _db;
    await database.transaction((transaction) async {
      for (final message in messages) {
        await _upsertMessage(transaction, scope, message);
      }
    });
  }

  Future<void> _upsertMessage(
    DatabaseExecutor executor,
    String scope,
    ChatNuMessage message,
  ) async {
    if (message.clientId != null) {
      await executor.delete(
        'messages',
        where:
            'scope = ? AND conversation_id = ? AND (id = ? OR client_id = ?)',
        whereArgs: <Object?>[
          scope,
          message.conversationId,
          message.id,
          message.clientId,
        ],
      );
    } else {
      await executor.delete(
        'messages',
        where: 'scope = ? AND conversation_id = ? AND id = ?',
        whereArgs: <Object?>[scope, message.conversationId, message.id],
      );
    }
    await executor.insert('messages', <String, Object?>{
      'scope': scope,
      'conversation_id': message.conversationId,
      'id': message.id,
      'client_id': message.clientId,
      'sent_at': message.sentAt.toUtc().millisecondsSinceEpoch,
      'payload': jsonEncode(_messageToJson(message)),
    });
  }

  @override
  Future<void> replaceMessage(
    String scope,
    String conversationId,
    String oldId,
    ChatNuMessage replacement,
  ) async {
    final database = await _db;
    await database.transaction((transaction) async {
      await transaction.delete(
        'messages',
        where: 'scope = ? AND conversation_id = ? AND id = ?',
        whereArgs: <Object?>[scope, conversationId, oldId],
      );
      await _upsertMessage(transaction, scope, replacement);
    });
  }

  @override
  Future<void> saveDraft(
    String scope,
    String conversationId,
    String text,
  ) async {
    final database = await _db;
    if (text.isEmpty) {
      await database.delete(
        'drafts',
        where: 'scope = ? AND conversation_id = ?',
        whereArgs: <Object?>[scope, conversationId],
      );
      return;
    }
    await database.insert('drafts', <String, Object?>{
      'scope': scope,
      'conversation_id': conversationId,
      'text': text,
      'updated_at': DateTime.now().toUtc().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> savePagination(
    String scope,
    String conversationId,
    CachedConversationPage page,
  ) async {
    final database = await _db;
    await database.insert('pagination', <String, Object?>{
      'scope': scope,
      'conversation_id': conversationId,
      'oldest_loaded_at': page.oldestLoadedAt?.toUtc().millisecondsSinceEpoch,
      'has_more': page.hasMore ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> saveSyncCursor(String scope, String cursor) async {
    final database = await _db;
    await database.insert('sync_state', <String, Object?>{
      'scope': scope,
      'cursor': cursor,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> close() async {
    final future = _database;
    _database = null;
    if (future != null) await (await future).close();
  }
}

Map<String, dynamic> _conversationToJson(ChatNuConversation value) =>
    <String, dynamic>{
      'id': value.id,
      'title': value.title,
      'kind': value.kind.name,
      'members': value.members.map(_userToJson).toList(growable: false),
      'lastMessagePreview': value.lastMessagePreview,
      'lastActivityAt': value.lastActivityAt.toUtc().toIso8601String(),
      'avatarUrl': value.avatarUrl,
      'unreadCount': value.unreadCount,
      'isPinned': value.isPinned,
      'isMuted': value.isMuted,
    };

ChatNuConversation _conversationFromPayload(String payload) {
  final json = _decodedMap(payload);
  return ChatNuConversation(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    kind: json['kind'] == ConversationKind.group.name
        ? ConversationKind.group
        : ConversationKind.direct,
    members: (json['members'] is List ? json['members'] as List : const <Object>[])
        .whereType<Map>()
        .map(
          (item) => _userFromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList(growable: false),
    lastMessagePreview: json['lastMessagePreview']?.toString() ?? '',
    lastActivityAt: _date(json['lastActivityAt']),
    avatarUrl: _nullableString(json['avatarUrl']),
    unreadCount: _int(json['unreadCount']),
    isPinned: json['isPinned'] == true,
    isMuted: json['isMuted'] == true,
  );
}

Map<String, dynamic> _userToJson(ChatNuUser value) => <String, dynamic>{
  'id': value.id,
  'username': value.username,
  'displayName': value.displayName,
  'avatarUrl': value.avatarUrl,
  'bio': value.bio,
};

ChatNuUser _userFromJson(Map<String, dynamic> json) => ChatNuUser(
  id: json['id']?.toString() ?? '',
  username: json['username']?.toString() ?? '',
  displayName: json['displayName']?.toString() ?? '',
  avatarUrl: _nullableString(json['avatarUrl']),
  bio: _nullableString(json['bio']),
);

Map<String, dynamic> _messageToJson(ChatNuMessage value) => <String, dynamic>{
  'id': value.id,
  'clientId': value.clientId,
  'conversationId': value.conversationId,
  'senderId': value.senderId,
  'senderName': value.senderName,
  'body': value.body,
  'sentAt': value.sentAt.toUtc().toIso8601String(),
  'type': value.type.name,
  'deliveryState': value.deliveryState.name,
  'attachmentId': value.attachmentId,
  'fileName': value.fileName,
  'mimeType': value.mimeType,
  'sizeBytes': value.sizeBytes,
  'attachmentKeyBase64': value.attachmentKeyBase64,
  'attachmentNonceBase64': value.attachmentNonceBase64,
  'locationLatitude': value.locationLatitude,
  'locationLongitude': value.locationLongitude,
  'mediaDurationMs': value.mediaDurationMs,
  'isVideoNote': value.isVideoNote,
};

ChatNuMessage _messageFromPayload(String payload) {
  final json = _decodedMap(payload);
  return ChatNuMessage(
    id: json['id']?.toString() ?? '',
    clientId: _nullableString(json['clientId']),
    conversationId: json['conversationId']?.toString() ?? '',
    senderId: json['senderId']?.toString() ?? '',
    senderName: json['senderName']?.toString() ?? '',
    body: json['body']?.toString() ?? '',
    sentAt: _date(json['sentAt']),
    type: _messageType(json['type']),
    deliveryState: _deliveryState(json['deliveryState']),
    attachmentId: _nullableString(json['attachmentId']),
    fileName: _nullableString(json['fileName']),
    mimeType: _nullableString(json['mimeType']),
    sizeBytes: _nullableInt(json['sizeBytes']),
    attachmentKeyBase64: _nullableString(json['attachmentKeyBase64']),
    attachmentNonceBase64: _nullableString(json['attachmentNonceBase64']),
    locationLatitude: _nullableDouble(json['locationLatitude']),
    locationLongitude: _nullableDouble(json['locationLongitude']),
    mediaDurationMs: _nullableInt(json['mediaDurationMs']),
    isVideoNote: json['isVideoNote'] == true,
  );
}

Map<String, dynamic> _decodedMap(String payload) {
  final value = jsonDecode(payload);
  if (value is! Map) throw const FormatException('Expected cached JSON object.');
  return value.map((key, item) => MapEntry(key.toString(), item));
}

DateTime _date(Object? value) =>
    DateTime.tryParse(value?.toString() ?? '')?.toLocal() ??
    DateTime.fromMillisecondsSinceEpoch(0);

String? _nullableString(Object? value) {
  final text = value?.toString();
  return text == null || text.isEmpty || text == 'null' ? null : text;
}

int _int(Object? value) => _nullableInt(value) ?? 0;

int? _nullableInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

double? _nullableDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

ChatNuMessageType _messageType(Object? value) {
  final name = value?.toString();
  return ChatNuMessageType.values.firstWhere(
    (item) => item.name == name,
    orElse: () => ChatNuMessageType.text,
  );
}

MessageDeliveryState _deliveryState(Object? value) {
  final name = value?.toString();
  return MessageDeliveryState.values.firstWhere(
    (item) => item.name == name,
    orElse: () => MessageDeliveryState.sentToServer,
  );
}
