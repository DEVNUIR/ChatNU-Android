import 'package:chatnu/core/config/server_config_repository.dart';
import 'package:chatnu/core/config/server_endpoint.dart';
import 'package:chatnu/core/crypto/device_e2ee.dart';
import 'package:chatnu/core/crypto/portable_identity_store.dart';
import 'package:chatnu/core/network/chatnu_api_client.dart';
import 'package:chatnu/core/platform/chatnu_native_bridge.dart';
import 'package:chatnu/core/storage/credential_vault.dart';
import 'package:chatnu/core/storage/secret_store.dart';
import 'package:chatnu/features/home/data/messenger_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ChatNuAppMode { production, demo }

final appModeProvider = Provider<ChatNuAppMode>(
  (ref) => ChatNuAppMode.production,
);

final secretStoreProvider = Provider<SecretStore>(
  (ref) => FlutterSecretStore(),
);

final nativeBridgeProvider = Provider<ChatNuNativeBridge>(
  (ref) => ChatNuNativeBridge(),
);

final credentialVaultProvider = Provider<CredentialVault>((ref) {
  return CredentialVault(
    store: ref.watch(secretStoreProvider),
    bridge: ref.watch(nativeBridgeProvider),
  );
});

final serverConfigRepositoryProvider = Provider<ServerConfigRepository>((ref) {
  return ServerConfigRepository(
    store: ref.watch(secretStoreProvider),
    bridge: ref.watch(nativeBridgeProvider),
  );
});

class ServerEndpointController extends Notifier<ChatNuServerEndpoint> {
  @override
  ChatNuServerEndpoint build() => ChatNuServerEndpoint.production();

  Future<void> restore() async {
    state = await ref.read(serverConfigRepositoryProvider).load();
  }

  Future<ChatNuServerEndpoint> configure(String rawValue) async {
    final endpoint = ChatNuServerEndpoint.parse(rawValue);
    await ref.read(serverConfigRepositoryProvider).save(endpoint);
    state = endpoint;
    return endpoint;
  }

  Future<void> reset() async {
    await ref.read(serverConfigRepositoryProvider).reset();
    state = ChatNuServerEndpoint.production();
  }
}

final serverEndpointProvider =
    NotifierProvider<ServerEndpointController, ChatNuServerEndpoint>(
      ServerEndpointController.new,
    );

final portableIdentityStoreProvider = Provider<PortableIdentityStore>((ref) {
  return PortableIdentityStore(ref.watch(secretStoreProvider));
});

final deviceE2eeProvider = Provider<DeviceE2ee>((ref) {
  return DeviceE2ee(
    portableIdentities: ref.watch(portableIdentityStoreProvider),
    nativeBridge: ref.watch(nativeBridgeProvider),
  );
});

final apiClientProvider = Provider<ChatNuApiClient>((ref) {
  return ChatNuApiClient(
    endpoint: ref.watch(serverEndpointProvider),
    vault: ref.watch(credentialVaultProvider),
  );
});

final messengerRepositoryProvider = Provider<MessengerRepository>((ref) {
  return MessengerRepository(
    api: ref.watch(apiClientProvider),
    e2ee: ref.watch(deviceE2eeProvider),
    vault: ref.watch(credentialVaultProvider),
  );
});
