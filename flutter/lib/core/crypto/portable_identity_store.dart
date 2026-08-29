import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:chatnu/core/storage/secret_store.dart';
import 'package:pointycastle/export.dart';

class PortableRsaIdentity {
  const PortableRsaIdentity({
    required this.publicKey,
    required this.privateKey,
  });

  final RSAPublicKey publicKey;
  final RSAPrivateKey privateKey;

  factory PortableRsaIdentity.fromJson(Map<dynamic, dynamic> json) {
    final n = BigInt.parse(json['n'].toString(), radix: 16);
    final e = BigInt.parse(json['e'].toString(), radix: 16);
    final d = BigInt.parse(json['d'].toString(), radix: 16);
    final p = BigInt.parse(json['p'].toString(), radix: 16);
    final q = BigInt.parse(json['q'].toString(), radix: 16);
    return PortableRsaIdentity(
      publicKey: RSAPublicKey(n, e),
      privateKey: RSAPrivateKey(n, d, p, q),
    );
  }

  Map<String, String> toJson() => <String, String>{
    'n': publicKey.modulus!.toRadixString(16),
    'e': publicKey.exponent!.toRadixString(16),
    'd': privateKey.privateExponent!.toRadixString(16),
    'p': privateKey.p!.toRadixString(16),
    'q': privateKey.q!.toRadixString(16),
  };
}

class PortableIdentityStore {
  PortableIdentityStore(this._secrets);

  final SecretStore _secrets;

  Future<PortableRsaIdentity> getOrCreate(String account) async {
    final key = _storageKey(account);
    final stored = await _secrets.read(key);
    if (stored != null) {
      try {
        final value = jsonDecode(stored);
        if (value is Map) return PortableRsaIdentity.fromJson(value);
      } on FormatException {
        await _secrets.delete(key);
      }
    }

    final generator = RSAKeyGenerator()
      ..init(
        ParametersWithRandom(
          RSAKeyGeneratorParameters(BigInt.from(65537), 3072, 64),
          secureRandom(),
        ),
      );
    final pair = generator.generateKeyPair();
    final identity = PortableRsaIdentity(
      publicKey: pair.publicKey,
      privateKey: pair.privateKey,
    );
    await _secrets.write(key, jsonEncode(identity.toJson()));
    return identity;
  }

  Future<void> importForCompatibility(
    String account,
    PortableRsaIdentity identity,
  ) async {
    await _secrets.write(_storageKey(account), jsonEncode(identity.toJson()));
  }

  static SecureRandom secureRandom() {
    final seed = Uint8List(32);
    final random = Random.secure();
    for (var i = 0; i < seed.length; i++) {
      seed[i] = random.nextInt(256);
    }
    return FortunaRandom()..seed(KeyParameter(seed));
  }

  String _storageKey(String account) {
    final digest = SHA256Digest().process(
      Uint8List.fromList(utf8.encode(account.trim().toLowerCase())),
    );
    final prefix = digest
        .take(12)
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join();
    return 'chatnu.e2ee.identity.$prefix';
  }
}
