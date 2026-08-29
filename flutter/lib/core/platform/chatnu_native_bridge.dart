import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';

class LegacyAndroidState {
  const LegacyAndroidState({this.session, this.server});

  final Map<String, dynamic>? session;
  final Map<String, dynamic>? server;
}

class ChatNuNativeBridge {
  ChatNuNativeBridge({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('ir.devnu.chatnu/native');

  final MethodChannel _channel;

  bool get isAndroid => Platform.isAndroid;

  Future<String?> publicIdentityKey(String account) async {
    if (!isAndroid) return null;
    return _channel.invokeMethod<String>('identityPublicKey', <String, Object?>{
      'account': account,
    });
  }

  Future<List<int>?> unwrapContentKey({
    required String account,
    required String wrappedKeyBase64,
  }) async {
    if (!isAndroid) return null;
    final value = await _channel.invokeMethod<Uint8List>(
      'unwrapContentKey',
      <String, Object?>{
        'account': account,
        'wrappedKey': wrappedKeyBase64,
      },
    );
    return value?.toList(growable: false);
  }

  Future<LegacyAndroidState> readLegacyState() async {
    if (!isAndroid) return const LegacyAndroidState();
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'readLegacyState',
    );
    if (result == null) return const LegacyAndroidState();
    return LegacyAndroidState(
      session: _map(result['session']),
      server: _map(result['server']),
    );
  }

  static Map<String, dynamic>? _map(Object? value) {
    if (value is! Map) return null;
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
}
