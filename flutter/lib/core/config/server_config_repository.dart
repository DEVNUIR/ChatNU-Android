import 'package:chatnu/core/config/server_endpoint.dart';
import 'package:chatnu/core/platform/chatnu_native_bridge.dart';
import 'package:chatnu/core/storage/secret_store.dart';

class ServerConfigRepository {
  ServerConfigRepository({
    required SecretStore store,
    required ChatNuNativeBridge bridge,
  }) : _store = store,
       _bridge = bridge;

  static const _key = 'chatnu.server.enrollment.v1';

  final SecretStore _store;
  final ChatNuNativeBridge _bridge;

  Future<ChatNuServerEndpoint> load() async {
    final stored = await _store.read(_key);
    if (stored != null) {
      try {
        return ChatNuServerEndpoint.parse(stored);
      } on FormatException {
        await _store.delete(_key);
      }
    }

    final legacy = await _bridge.readLegacyState();
    final apiUrl = legacy.server?['apiUrl']?.toString();
    if (apiUrl != null && apiUrl.isNotEmpty) {
      final pin = legacy.server?['tlsCaPin']?.toString();
      final enrollment = pin == null || pin.isEmpty
          ? apiUrl
          : '$apiUrl#chatnu-ca=$pin';
      try {
        final endpoint = ChatNuServerEndpoint.parse(enrollment);
        await save(endpoint);
        return endpoint;
      } on FormatException {
        // Fall through to the production origin.
      }
    }
    return ChatNuServerEndpoint.production();
  }

  Future<void> save(ChatNuServerEndpoint endpoint) =>
      _store.write(_key, endpoint.enrollmentValue);

  Future<void> reset() => _store.delete(_key);
}
