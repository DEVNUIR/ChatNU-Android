import 'dart:convert';
import 'dart:typed_data';

import 'package:chatnu/core/crypto/portable_identity_store.dart';
import 'package:chatnu/core/crypto/rsa_der_codec.dart';
import 'package:chatnu/core/platform/chatnu_native_bridge.dart';
import 'package:pointycastle/export.dart';

class RecipientDeviceKey {
  const RecipientDeviceKey({
    required this.deviceId,
    required this.publicKeyBase64,
  });

  final String deviceId;
  final String publicKeyBase64;
}

class E2eeEnvelope {
  const E2eeEnvelope({
    required this.ciphertextBase64,
    required this.nonceBase64,
    required this.wrappedKeys,
    this.protocolVersion = DeviceE2ee.protocolVersion,
  });

  final String ciphertextBase64;
  final String nonceBase64;
  final Map<String, String> wrappedKeys;
  final String protocolVersion;
}

class EncryptedAttachment {
  const EncryptedAttachment({
    required this.ciphertext,
    required this.keyBase64,
    required this.nonceBase64,
  });

  final Uint8List ciphertext;
  final String keyBase64;
  final String nonceBase64;
}

class DeviceE2ee {
  DeviceE2ee({
    required PortableIdentityStore portableIdentities,
    required ChatNuNativeBridge nativeBridge,
  }) : _portableIdentities = portableIdentities,
       _nativeBridge = nativeBridge;

  static const protocolVersion = 'chatnu-e2ee-rsa3072-aes256gcm-v1';

  final PortableIdentityStore _portableIdentities;
  final ChatNuNativeBridge _nativeBridge;

  Future<String> publicKeyBase64(String account) async {
    final native = await _nativeBridge.publicIdentityKey(account);
    if (native != null && native.isNotEmpty) return native;
    final identity = await _portableIdentities.getOrCreate(account);
    return base64.encode(
      RsaDerCodec.encodeSubjectPublicKeyInfo(identity.publicKey),
    );
  }

  Future<E2eeEnvelope> encryptMessage({
    required Uint8List plaintext,
    required List<RecipientDeviceKey> recipientKeys,
    required String aad,
  }) async {
    if (recipientKeys.isEmpty) {
      throw StateError('No recipient device keys are available.');
    }
    final contentKey = PortableIdentityStore.secureRandom().nextBytes(32);
    final nonce = PortableIdentityStore.secureRandom().nextBytes(12);
    final ciphertext = _aesGcm(
      encrypt: true,
      data: plaintext,
      key: contentKey,
      nonce: nonce,
      aad: Uint8List.fromList(utf8.encode(aad)),
    );

    final wrappedKeys = <String, String>{};
    final seen = <String>{};
    for (final recipient in recipientKeys) {
      if (!seen.add(recipient.deviceId)) continue;
      final publicKey = RsaDerCodec.decodeSubjectPublicKeyInfo(
        base64.decode(recipient.publicKeyBase64),
      );
      wrappedKeys[recipient.deviceId] = base64.encode(
        _wrapContentKey(publicKey, contentKey),
      );
    }
    return E2eeEnvelope(
      ciphertextBase64: base64.encode(ciphertext),
      nonceBase64: base64.encode(nonce),
      wrappedKeys: wrappedKeys,
    );
  }

  Future<Uint8List> decryptMessage({
    required String account,
    required String deviceId,
    required String ciphertextBase64,
    required String nonceBase64,
    required Map<String, dynamic>? metadata,
    required String aad,
  }) async {
    final rawWrapped = metadata?['wrappedKeys'];
    if (rawWrapped is! Map) {
      throw StateError('Encrypted message is missing wrappedKeys.');
    }
    String? wrappedKey;
    for (final entry in rawWrapped.entries) {
      if (entry.key.toString() == deviceId) {
        wrappedKey = entry.value?.toString();
        break;
      }
    }
    if (wrappedKey == null || wrappedKey.isEmpty) {
      throw StateError(
        'This message was not encrypted for the current device.',
      );
    }

    Uint8List contentKey;
    final native = await _nativeBridge.unwrapContentKey(
      account: account,
      wrappedKeyBase64: wrappedKey,
    );
    if (native != null) {
      contentKey = Uint8List.fromList(native);
    } else {
      final identity = await _portableIdentities.getOrCreate(account);
      contentKey = _unwrapContentKey(
        identity.privateKey,
        Uint8List.fromList(base64.decode(wrappedKey)),
      );
    }

    return _aesGcm(
      encrypt: false,
      data: Uint8List.fromList(base64.decode(ciphertextBase64)),
      key: contentKey,
      nonce: Uint8List.fromList(base64.decode(nonceBase64)),
      aad: Uint8List.fromList(utf8.encode(aad)),
    );
  }

  EncryptedAttachment encryptAttachment(Uint8List plaintext) {
    final key = PortableIdentityStore.secureRandom().nextBytes(32);
    final nonce = PortableIdentityStore.secureRandom().nextBytes(12);
    return EncryptedAttachment(
      ciphertext: _aesGcm(
        encrypt: true,
        data: plaintext,
        key: key,
        nonce: nonce,
        aad: Uint8List(0),
      ),
      keyBase64: base64.encode(key),
      nonceBase64: base64.encode(nonce),
    );
  }

  Uint8List decryptAttachment({
    required Uint8List ciphertext,
    required String keyBase64,
    required String nonceBase64,
  }) {
    return _aesGcm(
      encrypt: false,
      data: ciphertext,
      key: Uint8List.fromList(base64.decode(keyBase64)),
      nonce: Uint8List.fromList(base64.decode(nonceBase64)),
      aad: Uint8List(0),
    );
  }

  Uint8List _aesGcm({
    required bool encrypt,
    required Uint8List data,
    required Uint8List key,
    required Uint8List nonce,
    required Uint8List aad,
  }) {
    final cipher = GCMBlockCipher(AESEngine())
      ..init(encrypt, AEADParameters(KeyParameter(key), 128, nonce, aad));
    return cipher.process(data);
  }

  Uint8List _wrapContentKey(RSAPublicKey key, Uint8List contentKey) {
    final cipher = OAEPEncoding.withSHA256(RSAEngine())
      ..mgf1Hash = SHA1Digest();
    cipher.init(
      true,
      ParametersWithRandom(
        PublicKeyParameter<RSAPublicKey>(key),
        PortableIdentityStore.secureRandom(),
      ),
    );
    return cipher.process(contentKey);
  }

  Uint8List _unwrapContentKey(RSAPrivateKey key, Uint8List wrappedKey) {
    final cipher = OAEPEncoding.withSHA256(RSAEngine())
      ..mgf1Hash = SHA1Digest();
    cipher.init(false, PrivateKeyParameter<RSAPrivateKey>(key));
    return cipher.process(wrappedKey);
  }
}
