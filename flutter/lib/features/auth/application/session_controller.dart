import 'dart:io';
import 'dart:typed_data';

import 'package:chatnu/core/config/server_endpoint.dart';
import 'package:chatnu/core/di/app_providers.dart';
import 'package:chatnu/core/network/api_models.dart';
import 'package:chatnu/core/network/chatnu_api_client.dart';
import 'package:chatnu/core/storage/credential_vault.dart';
import 'package:chatnu/features/accounts/domain/chatnu_user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ChatNuSessionStatus { booting, authenticated, unauthenticated }

class ChatNuSessionState {
  const ChatNuSessionState({
    required this.status,
    this.user,
    this.error,
    this.recoveryCode,
    this.offline = false,
  });

  const ChatNuSessionState.booting()
    : this(status: ChatNuSessionStatus.booting);

  const ChatNuSessionState.unauthenticated({String? error})
    : this(status: ChatNuSessionStatus.unauthenticated, error: error);

  const ChatNuSessionState.authenticated(
    ChatNuUser user, {
    String? recoveryCode,
    bool offline = false,
  }) : this(
         status: ChatNuSessionStatus.authenticated,
         user: user,
         recoveryCode: recoveryCode,
         offline: offline,
       );

  final ChatNuSessionStatus status;
  final ChatNuUser? user;
  final String? error;
  final String? recoveryCode;
  final bool offline;

  bool get isAuthenticated => status == ChatNuSessionStatus.authenticated;
  bool get needsRecoveryCodeAcknowledgement =>
      isAuthenticated && recoveryCode != null;
}

class SessionController extends Notifier<ChatNuSessionState> {
  bool _bootstrapped = false;

  @override
  ChatNuSessionState build() {
    final mode = ref.watch(appModeProvider);
    if (mode == ChatNuAppMode.demo) {
      return const ChatNuSessionState.authenticated(
        ChatNuUser(
          id: 'me',
          username: 'chatnu_user',
          displayName: 'ChatNU User',
        ),
      );
    }
    if (!_bootstrapped) {
      _bootstrapped = true;
      Future<void>.microtask(bootstrap);
    }
    return const ChatNuSessionState.booting();
  }

  Future<void> bootstrap() async {
    if (ref.read(appModeProvider) == ChatNuAppMode.demo) return;
    try {
      await ref.read(serverEndpointProvider.notifier).restore();
      final vault = ref.read(credentialVaultProvider);
      final stored = await vault.hydrate();
      if (stored == null) {
        state = const ChatNuSessionState.unauthenticated();
        return;
      }
      state = ChatNuSessionState.authenticated(stored.user, offline: true);
      await _ensureDeviceIdentity(stored);
      if (vault.session == null) {
        state = const ChatNuSessionState.unauthenticated();
      } else {
        state = ChatNuSessionState.authenticated(stored.user);
      }
    } catch (_) {
      final stored = ref.read(credentialVaultProvider).session;
      if (stored == null) {
        state = const ChatNuSessionState.unauthenticated();
      } else {
        state = ChatNuSessionState.authenticated(stored.user, offline: true);
      }
    }
  }

  Future<String?> login({
    required String username,
    required String password,
  }) async {
    final normalized = username.trim().toLowerCase();
    if (normalized.isEmpty || password.isEmpty) {
      return 'Username and password are required.';
    }
    try {
      final endpoint = ref.read(serverEndpointProvider);
      if (endpoint.usesEmergencyTls) {
        return 'Emergency pinned TLS is not enabled in the Flutter transport yet.';
      }
      final account = '${endpoint.identityNamespace}|$normalized';
      final publicKey = await ref
          .read(deviceE2eeProvider)
          .publicKeyBase64(account);
      final response = await ref
          .read(apiClientProvider)
          .login(
            username: normalized,
            password: password,
            deviceName: _deviceName(),
            identityPublicKey: publicKey,
          );
      final stored = _storedSession(response, account);
      await ref.read(credentialVaultProvider).persist(stored);
      state = ChatNuSessionState.authenticated(stored.user);
      return null;
    } on ChatNuApiException catch (error) {
      return _friendlyAuthError(error);
    } catch (error) {
      return error.toString();
    }
  }

  Future<String?> register({
    required String username,
    required String password,
    required String displayName,
  }) async {
    final normalized = username.trim().toLowerCase();
    if (normalized.isEmpty || password.isEmpty || displayName.trim().isEmpty) {
      return 'Username, display name, and password are required.';
    }
    try {
      final endpoint = ref.read(serverEndpointProvider);
      if (endpoint.usesEmergencyTls) {
        return 'Emergency pinned TLS is not enabled in the Flutter transport yet.';
      }
      final account = '${endpoint.identityNamespace}|$normalized';
      final publicKey = await ref
          .read(deviceE2eeProvider)
          .publicKeyBase64(account);
      final response = await ref
          .read(apiClientProvider)
          .register(
            username: normalized,
            password: password,
            displayName: displayName.trim(),
            deviceName: _deviceName(),
            identityPublicKey: publicKey,
          );
      final stored = _storedSession(response, account);
      await ref.read(credentialVaultProvider).persist(stored);
      state = ChatNuSessionState.authenticated(
        stored.user,
        recoveryCode: response.recoveryCode,
      );
      return null;
    } on ChatNuApiException catch (error) {
      return _friendlyAuthError(error);
    } catch (error) {
      return error.toString();
    }
  }

  void acknowledgeRecoveryCode() {
    final user = state.user;
    if (user == null || !state.needsRecoveryCodeAcknowledgement) return;
    state = ChatNuSessionState.authenticated(user, offline: state.offline);
  }

  Future<String?> recover({
    required String username,
    required String recoveryCode,
    required String newPassword,
  }) async {
    final normalized = username.trim().toLowerCase();
    if (normalized.isEmpty ||
        recoveryCode.trim().isEmpty ||
        newPassword.isEmpty) {
      return 'Username, recovery code, and new password are required.';
    }
    try {
      await ref
          .read(apiClientProvider)
          .recover(
            username: normalized,
            recoveryCode: recoveryCode.trim(),
            newPassword: newPassword,
          );
      await ref.read(credentialVaultProvider).clear();
      state = const ChatNuSessionState.unauthenticated();
      return null;
    } on ChatNuApiException catch (error) {
      return _friendlyAuthError(error);
    } catch (error) {
      return error.toString();
    }
  }

  Future<String?> updateProfile({
    required String displayName,
    required String? bio,
  }) async {
    final cleanName = displayName.trim();
    final cleanBio = bio?.trim();
    if (cleanName.isEmpty || cleanName.length > 80) {
      return 'Display name must be between 1 and 80 characters.';
    }
    if ((cleanBio?.length ?? 0) > 160) {
      return 'Bio must be 160 characters or fewer.';
    }
    try {
      final user = await ref
          .read(apiClientProvider)
          .updateProfile(
            displayName: cleanName,
            bio: cleanBio?.isEmpty == true ? null : cleanBio,
          );
      await _applyUser(user);
      return null;
    } on ChatNuApiException catch (error) {
      return error.message;
    } catch (error) {
      return error.toString();
    }
  }

  Future<String?> uploadAvatar({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
      return 'Avatar must be a non-empty image up to 5 MiB.';
    }
    try {
      final user = await ref
          .read(apiClientProvider)
          .uploadAvatar(bytes: bytes, fileName: fileName);
      await _applyUser(user);
      return null;
    } on ChatNuApiException catch (error) {
      return error.message;
    } catch (error) {
      return error.toString();
    }
  }

  Future<String?> removeAvatar() async {
    try {
      final user = await ref.read(apiClientProvider).removeAvatar();
      await _applyUser(user);
      return null;
    } on ChatNuApiException catch (error) {
      return error.message;
    } catch (error) {
      return error.toString();
    }
  }

  Future<String?> switchServer(String rawValue) async {
    try {
      ChatNuServerEndpoint.parse(rawValue);
    } on FormatException catch (error) {
      return error.message;
    }
    try {
      await ref.read(apiClientProvider).logout();
    } catch (_) {
      // Server switching must still clear the local token if the old server is down.
    }
    await ref.read(credentialVaultProvider).clear();
    try {
      await ref.read(serverEndpointProvider.notifier).configure(rawValue);
      state = const ChatNuSessionState.unauthenticated();
      return null;
    } on FormatException catch (error) {
      return error.message;
    } catch (error) {
      return error.toString();
    }
  }

  Future<String?> resetServer() async {
    try {
      await ref.read(apiClientProvider).logout();
    } catch (_) {}
    await ref.read(credentialVaultProvider).clear();
    await ref.read(serverEndpointProvider.notifier).reset();
    state = const ChatNuSessionState.unauthenticated();
    return null;
  }

  Future<void> logout() async {
    try {
      await ref.read(apiClientProvider).logout();
    } catch (_) {
      // Local logout must succeed even when the server is unreachable.
    }
    await ref.read(credentialVaultProvider).clear();
    state = const ChatNuSessionState.unauthenticated();
  }

  Future<void> _applyUser(UserDto dto) async {
    final user = ChatNuUser(
      id: dto.id,
      username: dto.username,
      displayName: dto.displayName,
      avatarUrl: dto.avatarUrl,
      bio: dto.bio,
    );
    await ref.read(credentialVaultProvider).updateUser(user);
    state = ChatNuSessionState.authenticated(user, offline: state.offline);
  }

  Future<void> _ensureDeviceIdentity(StoredSession stored) async {
    final api = ref.read(apiClientProvider);
    await api.session();
    final publicKey = await ref
        .read(deviceE2eeProvider)
        .publicKeyBase64(stored.cryptoAccount);
    await api.updateIdentityKey(publicKey);
  }

  StoredSession _storedSession(AuthResponse response, String account) {
    return StoredSession(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
      deviceId: response.deviceId,
      cryptoAccount: account,
      user: ChatNuUser(
        id: response.user.id,
        username: response.user.username,
        displayName: response.user.displayName,
        avatarUrl: response.user.avatarUrl,
        bio: response.user.bio,
      ),
    );
  }

  String _deviceName() {
    final host = Platform.localHostname.trim();
    final system = Platform.operatingSystem;
    return host.isEmpty ? 'ChatNU $system' : '$host · $system';
  }

  String _friendlyAuthError(ChatNuApiException error) {
    return switch (error.statusCode) {
      400 => 'The submitted account information is invalid.',
      401 => 'The username, password, or recovery code is incorrect.',
      403 => 'This server does not allow that authentication action.',
      409 => 'That username is already taken.',
      429 => 'Too many requests. Try again shortly.',
      _ => error.message,
    };
  }
}

final sessionProvider = NotifierProvider<SessionController, ChatNuSessionState>(
  SessionController.new,
);
