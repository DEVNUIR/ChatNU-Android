import 'dart:convert';

import 'package:chatnu/core/platform/chatnu_native_bridge.dart';
import 'package:chatnu/core/storage/secret_store.dart';
import 'package:chatnu/features/accounts/domain/chatnu_user.dart';

class StoredSession {
  const StoredSession({
    required this.accessToken,
    required this.refreshToken,
    required this.deviceId,
    required this.cryptoAccount,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final String deviceId;
  final String cryptoAccount;
  final ChatNuUser user;

  StoredSession copyWith({String? accessToken, String? refreshToken}) {
    return StoredSession(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      deviceId: deviceId,
      cryptoAccount: cryptoAccount,
      user: user,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'deviceId': deviceId,
    'cryptoAccount': cryptoAccount,
    'user': <String, dynamic>{
      'id': user.id,
      'username': user.username,
      'displayName': user.displayName,
      'avatarUrl': user.avatarUrl,
      'bio': user.bio,
    },
  };

  static StoredSession? fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    if (userJson is! Map) return null;
    final user = userJson.map((key, value) => MapEntry(key.toString(), value));
    final accessToken = json['accessToken']?.toString();
    final refreshToken = json['refreshToken']?.toString();
    final deviceId = json['deviceId']?.toString();
    final cryptoAccount = json['cryptoAccount']?.toString();
    final userId = user['id']?.toString();
    final username = user['username']?.toString();
    if (<String?>[
      accessToken,
      refreshToken,
      deviceId,
      cryptoAccount,
      userId,
      username,
    ].any((value) => value == null || value!.isEmpty)) {
      return null;
    }
    return StoredSession(
      accessToken: accessToken!,
      refreshToken: refreshToken!,
      deviceId: deviceId!,
      cryptoAccount: cryptoAccount!,
      user: ChatNuUser(
        id: userId!,
        username: username!,
        displayName: user['displayName']?.toString() ?? username,
        avatarUrl: user['avatarUrl']?.toString(),
        bio: user['bio']?.toString(),
      ),
    );
  }

  static StoredSession? fromLegacy(Map<String, dynamic>? legacy) {
    if (legacy == null) return null;
    return fromJson(<String, dynamic>{
      'accessToken': legacy['accessToken'],
      'refreshToken': legacy['refreshToken'],
      'deviceId': legacy['deviceId'],
      'cryptoAccount': legacy['cryptoAccount'],
      'user': <String, dynamic>{
        'id': legacy['userId'],
        'username': legacy['username'],
        'displayName': legacy['displayName'],
        'avatarUrl': legacy['avatarUrl'],
        'bio': legacy['bio'],
      },
    });
  }
}

class CredentialVault {
  CredentialVault({required SecretStore store, required ChatNuNativeBridge bridge})
    : _store = store,
      _bridge = bridge;

  static const _sessionKey = 'chatnu.session.v1';

  final SecretStore _store;
  final ChatNuNativeBridge _bridge;
  StoredSession? _session;

  StoredSession? get session => _session;
  String? get accessToken => _session?.accessToken;
  String? get refreshToken => _session?.refreshToken;
  String? get deviceId => _session?.deviceId;
  String? get cryptoAccount => _session?.cryptoAccount;

  Future<StoredSession?> hydrate() async {
    final encoded = await _store.read(_sessionKey);
    if (encoded != null) {
      try {
        final value = jsonDecode(encoded);
        if (value is Map) {
          _session = StoredSession.fromJson(
            value.map((key, item) => MapEntry(key.toString(), item)),
          );
        }
      } on FormatException {
        await _store.delete(_sessionKey);
      }
    }
    if (_session != null) return _session;

    final legacy = await _bridge.readLegacyState();
    final imported = StoredSession.fromLegacy(legacy.session);
    if (imported != null) await persist(imported);
    return _session;
  }

  Future<void> persist(StoredSession session) async {
    _session = session;
    await _store.write(_sessionKey, jsonEncode(session.toJson()));
  }

  Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final current = _session;
    if (current == null) return;
    await persist(
      current.copyWith(accessToken: accessToken, refreshToken: refreshToken),
    );
  }

  Future<void> clear() async {
    _session = null;
    await _store.delete(_sessionKey);
  }
}
