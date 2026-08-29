import 'dart:async';
import 'dart:typed_data';

import 'package:chatnu/core/config/server_endpoint.dart';
import 'package:chatnu/core/network/api_models.dart';
import 'package:chatnu/core/storage/credential_vault.dart';
import 'package:dio/dio.dart';

class ChatNuApiException implements Exception {
  const ChatNuApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ChatNuApiClient {
  ChatNuApiClient({
    required ChatNuServerEndpoint endpoint,
    required CredentialVault vault,
  }) : _endpoint = endpoint,
       _vault = vault,
       _dio = Dio(
         BaseOptions(
           baseUrl: endpoint.restBaseUrl,
           connectTimeout: const Duration(seconds: 15),
           receiveTimeout: const Duration(seconds: 60),
           sendTimeout: const Duration(seconds: 60),
           headers: const <String, dynamic>{'Accept': 'application/json'},
         ),
       ),
       _refreshDio = Dio(
         BaseOptions(
           baseUrl: endpoint.restBaseUrl,
           connectTimeout: const Duration(seconds: 15),
           receiveTimeout: const Duration(seconds: 20),
         ),
       ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _vault.accessToken;
          if (token != null &&
              token.isNotEmpty &&
              options.headers['Authorization'] == null &&
              !_isPublicAuthPath(options.path)) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final request = error.requestOptions;
          if (error.response?.statusCode != 401 ||
              request.extra['chatnuRetried'] == true ||
              request.path.endsWith('auth/refresh') ||
              _isPublicAuthPath(request.path)) {
            handler.next(error);
            return;
          }
          final refreshed = await _refreshAccessToken();
          if (refreshed == null) {
            handler.next(error);
            return;
          }
          request.extra['chatnuRetried'] = true;
          request.headers['Authorization'] = 'Bearer $refreshed';
          try {
            handler.resolve(await _dio.fetch<dynamic>(request));
          } on DioException catch (retryError) {
            handler.next(retryError);
          }
        },
      ),
    );
  }

  final ChatNuServerEndpoint _endpoint;
  final CredentialVault _vault;
  final Dio _dio;
  final Dio _refreshDio;
  Completer<String?>? _refreshing;

  ChatNuServerEndpoint get endpoint => _endpoint;

  Future<AuthResponse> register({
    required String username,
    required String password,
    required String displayName,
    required String deviceName,
    required String identityPublicKey,
  }) async {
    final json = await _postJson('auth/register', <String, dynamic>{
      'username': username,
      'password': password,
      'displayName': displayName,
      'deviceName': deviceName,
      'identityPublicKey': identityPublicKey,
    });
    return AuthResponse.fromJson(json);
  }

  Future<AuthResponse> login({
    required String username,
    required String password,
    required String deviceName,
    required String identityPublicKey,
  }) async {
    final json = await _postJson('auth/login', <String, dynamic>{
      'username': username,
      'password': password,
      'deviceName': deviceName,
      'identityPublicKey': identityPublicKey,
    });
    return AuthResponse.fromJson(json);
  }

  Future<void> recover({
    required String username,
    required String recoveryCode,
    required String newPassword,
  }) async {
    await _postJson('auth/recover', <String, dynamic>{
      'username': username,
      'recoveryCode': recoveryCode,
      'newPassword': newPassword,
    });
  }

  Future<void> logout() async {
    await _postJson('auth/logout', const <String, dynamic>{});
  }

  Future<SessionResponse> session() async =>
      SessionResponse.fromJson(await _getJson('session'));

  Future<UserDto> me() async {
    final json = await _getJson('me');
    final value = json['user'];
    return UserDto.fromJson(value is Map ? _map(value) : json);
  }

  Future<void> updateIdentityKey(String identityPublicKey) async {
    await _postJson('devices/identity-key', <String, dynamic>{
      'identityPublicKey': identityPublicKey,
    });
  }

  Future<void> updatePushToken(String? token) async {
    await _postJson('devices/push-token', <String, dynamic>{'token': token});
  }

  Future<List<UserDto>> searchUsers(String query) async {
    final json = await _getJson(
      'users/search',
      queryParameters: <String, dynamic>{'q': query},
    );
    return _list(
      json['users'],
    ).map((item) => UserDto.fromJson(_map(item))).toList(growable: false);
  }

  Future<List<ConversationDto>> conversations() async {
    final json = await _getJson('conversations');
    return _list(json['conversations'])
        .map((item) => ConversationDto.fromJson(_map(item)))
        .toList(growable: false);
  }

  Future<ConversationDto> createDirect(String username) async {
    final json = await _postJson('conversations/direct', <String, dynamic>{
      'username': username,
    });
    return ConversationDto.fromJson(_map(json['conversation']));
  }

  Future<ConversationDto> createGroup({
    required String title,
    required List<String> usernames,
  }) async {
    final json = await _postJson('conversations/group', <String, dynamic>{
      'title': title,
      'usernames': usernames,
    });
    return ConversationDto.fromJson(_map(json['conversation']));
  }

  Future<void> updateConversationPreferences(
    String conversationId, {
    bool? isPinned,
    bool? isMuted,
  }) async {
    await _patchJson(
      'conversations/$conversationId/preferences',
      <String, dynamic>{'isPinned': ?isPinned, 'isMuted': ?isMuted},
    );
  }

  Future<ConversationKeysResponse> conversationKeys(
    String conversationId,
  ) async {
    return ConversationKeysResponse.fromJson(
      await _getJson('conversations/$conversationId/keys'),
    );
  }

  Future<List<MessageDto>> messages(
    String conversationId, {
    String? before,
    int limit = 100,
  }) async {
    final json = await _getJson(
      'conversations/$conversationId/messages',
      queryParameters: <String, dynamic>{'before': ?before, 'limit': limit},
    );
    return _list(
      json['messages'],
    ).map((item) => MessageDto.fromJson(_map(item))).toList(growable: false);
  }

  Future<MessageDto> sendMessage({
    required String conversationId,
    required String clientId,
    required String type,
    required String ciphertext,
    required String nonce,
    required String protocolVersion,
    required Map<String, dynamic> metadata,
  }) async {
    final json = await _postJson('messages', <String, dynamic>{
      'conversationId': conversationId,
      'clientId': clientId,
      'type': type,
      'ciphertext': ciphertext,
      'nonce': nonce,
      'protocolVersion': protocolVersion,
      'metadata': metadata,
    });
    return MessageDto.fromJson(_map(json['message']));
  }

  Future<void> markRead(String conversationId) async {
    await _postJson(
      'conversations/$conversationId/read',
      const <String, dynamic>{},
    );
  }

  Future<AttachmentDto> uploadAttachment({
    required String conversationId,
    required Uint8List encryptedBytes,
  }) async {
    _ensureTransportAllowed();
    try {
      final response = await _dio.post<dynamic>(
        'attachments',
        data: FormData.fromMap(<String, dynamic>{
          'conversationId': conversationId,
          'file': MultipartFile.fromBytes(
            encryptedBytes,
            filename: 'chatnu.enc',
          ),
        }),
      );
      final json = _map(response.data);
      return AttachmentDto.fromJson(_map(json['attachment']));
    } on DioException catch (error) {
      throw _apiException(error);
    }
  }

  Future<Uint8List> downloadAttachment(String attachmentId) async {
    _ensureTransportAllowed();
    try {
      final response = await _dio.get<List<int>>(
        'attachments/$attachmentId/download',
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data ?? const <int>[]);
    } on DioException catch (error) {
      throw _apiException(error);
    }
  }

  Future<RtcConfigResponse> rtcConfig() async =>
      RtcConfigResponse.fromJson(await _getJson('rtc/config'));

  Future<List<PendingCallDto>> pendingCalls() async {
    final json = await _getJson('calls/pending');
    return _list(json['calls'])
        .map((item) => PendingCallDto.fromJson(_map(item)))
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> _getJson(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    _ensureTransportAllowed();
    try {
      final response = await _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
      );
      return _map(response.data);
    } on DioException catch (error) {
      throw _apiException(error);
    }
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> data,
  ) async {
    _ensureTransportAllowed();
    try {
      final response = await _dio.post<dynamic>(path, data: data);
      final body = response.data;
      return body is Map ? _map(body) : <String, dynamic>{};
    } on DioException catch (error) {
      throw _apiException(error);
    }
  }

  Future<Map<String, dynamic>> _patchJson(
    String path,
    Map<String, dynamic> data,
  ) async {
    _ensureTransportAllowed();
    try {
      final response = await _dio.patch<dynamic>(path, data: data);
      final body = response.data;
      return body is Map ? _map(body) : <String, dynamic>{};
    } on DioException catch (error) {
      throw _apiException(error);
    }
  }

  Future<String?> _refreshAccessToken() {
    final active = _refreshing;
    if (active != null) return active.future;
    final completer = Completer<String?>();
    _refreshing = completer;
    () async {
      try {
        final refreshToken = _vault.refreshToken;
        if (refreshToken == null || refreshToken.isEmpty) {
          completer.complete(null);
          return;
        }
        _ensureTransportAllowed();
        final response = await _refreshDio.post<dynamic>(
          'auth/refresh',
          data: <String, dynamic>{'refreshToken': refreshToken},
        );
        final refreshed = RefreshResponse.fromJson(_map(response.data));
        await _vault.updateTokens(
          accessToken: refreshed.accessToken,
          refreshToken: refreshed.refreshToken,
        );
        completer.complete(refreshed.accessToken);
      } catch (_) {
        await _vault.clear();
        completer.complete(null);
      } finally {
        _refreshing = null;
      }
    }();
    return completer.future;
  }

  void _ensureTransportAllowed() {
    if (_endpoint.usesEmergencyTls) {
      throw const ChatNuApiException(
        'This server uses ChatNU emergency CA pinning. Flutter will not weaken certificate validation; use a normally trusted certificate until native pinned transport parity is enabled.',
      );
    }
  }

  bool _isPublicAuthPath(String path) =>
      path.contains('auth/login') ||
      path.contains('auth/register') ||
      path.contains('auth/refresh') ||
      path.contains('auth/recover');

  ChatNuApiException _apiException(DioException error) {
    final body = error.response?.data;
    String? message;
    if (body is Map) {
      final json = _map(body);
      message = json['error']?.toString() ?? json['message']?.toString();
    }
    return ChatNuApiException(
      message ?? error.message ?? 'Unable to reach the ChatNU server.',
      statusCode: error.response?.statusCode,
    );
  }
}

Map<String, dynamic> _map(Object? value) {
  if (value is! Map) throw const FormatException('Expected a JSON object.');
  return value.map((key, item) => MapEntry(key.toString(), item));
}

List<dynamic> _list(Object? value) => value is List ? value : const <dynamic>[];
