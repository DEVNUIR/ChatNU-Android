import 'dart:typed_data';

import 'package:pointycastle/export.dart';

abstract final class RsaDerCodec {
  static Uint8List encodeSubjectPublicKeyInfo(RSAPublicKey key) {
    final rsaPublicKey = _derSequence(<Uint8List>[
      _derInteger(key.modulus!),
      _derInteger(key.exponent!),
    ]);
    final algorithm = _derSequence(<Uint8List>[
      Uint8List.fromList(<int>[
        0x06,
        0x09,
        0x2a,
        0x86,
        0x48,
        0x86,
        0xf7,
        0x0d,
        0x01,
        0x01,
        0x01,
      ]),
      Uint8List.fromList(<int>[0x05, 0x00]),
    ]);
    final bitStringValue = Uint8List(rsaPublicKey.length + 1)
      ..[0] = 0
      ..setRange(1, rsaPublicKey.length + 1, rsaPublicKey);
    return _derSequence(<Uint8List>[
      algorithm,
      _derObject(0x03, bitStringValue),
    ]);
  }

  static RSAPublicKey decodeSubjectPublicKeyInfo(List<int> source) {
    final top = _DerReader(Uint8List.fromList(source)).read(0x30);
    final topReader = _DerReader(top);
    topReader.read(0x30);
    final bitString = topReader.read(0x03);
    if (bitString.isEmpty || bitString.first != 0) {
      throw const FormatException('Invalid RSA subjectPublicKey bit string.');
    }
    final rsa = _DerReader(bitString.sublist(1)).read(0x30);
    final rsaReader = _DerReader(rsa);
    return RSAPublicKey(
      _bigInt(rsaReader.read(0x02)),
      _bigInt(rsaReader.read(0x02)),
    );
  }

  static Uint8List _derInteger(BigInt value) {
    var bytes = _bigIntBytes(value);
    if (bytes.isEmpty) bytes = Uint8List.fromList(<int>[0]);
    if ((bytes.first & 0x80) != 0) {
      bytes = Uint8List.fromList(<int>[0, ...bytes]);
    }
    return _derObject(0x02, bytes);
  }

  static Uint8List _derSequence(List<Uint8List> values) {
    final body = Uint8List.fromList(
      values.expand((value) => value).toList(growable: false),
    );
    return _derObject(0x30, body);
  }

  static Uint8List _derObject(int tag, Uint8List value) {
    return Uint8List.fromList(<int>[
      tag,
      ..._derLength(value.length),
      ...value,
    ]);
  }

  static List<int> _derLength(int length) {
    if (length < 128) return <int>[length];
    final bytes = <int>[];
    var remaining = length;
    while (remaining > 0) {
      bytes.insert(0, remaining & 0xff);
      remaining >>= 8;
    }
    return <int>[0x80 | bytes.length, ...bytes];
  }

  static Uint8List _bigIntBytes(BigInt value) {
    var hex = value.toRadixString(16);
    if (hex.length.isOdd) hex = '0$hex';
    final out = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < out.length; i++) {
      out[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return out;
  }

  static BigInt _bigInt(Uint8List bytes) {
    final significant = bytes.length > 1 && bytes.first == 0
        ? bytes.sublist(1)
        : bytes;
    if (significant.isEmpty) return BigInt.zero;
    final hex = significant
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join();
    return BigInt.parse(hex, radix: 16);
  }
}

class _DerReader {
  _DerReader(this.data);

  final Uint8List data;
  int offset = 0;

  Uint8List read(int expectedTag) {
    if (offset >= data.length || data[offset++] != expectedTag) {
      throw const FormatException('Unexpected DER tag.');
    }
    if (offset >= data.length) throw const FormatException('Missing DER length.');
    var length = data[offset++];
    if ((length & 0x80) != 0) {
      final count = length & 0x7f;
      if (count == 0 || count > 4 || offset + count > data.length) {
        throw const FormatException('Invalid DER length.');
      }
      length = 0;
      for (var i = 0; i < count; i++) {
        length = (length << 8) | data[offset++];
      }
    }
    if (offset + length > data.length) {
      throw const FormatException('DER value is truncated.');
    }
    final value = Uint8List.fromList(data.sublist(offset, offset + length));
    offset += length;
    return value;
  }
}
