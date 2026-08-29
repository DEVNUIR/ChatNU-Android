import 'dart:io';

import 'package:chatnu/core/di/app_providers.dart';
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
      final publicKey = await ref.read(deviceE2eeProvider).publicKeyBase64(account);
      final response = await ref.read(apiClientProvider).login(
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
      final publicKey = await ref.read(deviceE2eeProvider).publicKeyBase64(account);
      final response = await ref.read(apiClientProvider).register(
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

  Future<String?> recover({
    required String username,
    required String recoveryCode,
    required String newPassword,
  }) async {
    final normalized = username.trim().toLowerCase();
    if (normalized.isEmpty || recoveryCode.trim().isEmpty || newPassword.isEmpty) {
      return 'Username, recovery code, and new password are required.';
    }
    try {
      await ref.read(apiClientProvider).recover(
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

  Future<void> logout() async {
    try {
      await ref.read(apiClientProvider).logout();
    } catch (_) {
      // Local logout must succeed even when the server is unreachable.
    }
    await ref.read(credentialVaultProvider).clear();
    state = const ChatNuSessionState.unauthenticated();
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
