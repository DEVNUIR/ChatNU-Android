import 'dart:convert';

const _defaultRestUrl = 'https://api.devnu.ir/';
const _pinPrefix = 'chatnu-ca=';

class ChatNuServerEndpoint {
  const ChatNuServerEndpoint({required this.restUri, this.tlsCaPin});

  factory ChatNuServerEndpoint.production() =>
      ChatNuServerEndpoint.parse(_defaultRestUrl);

  factory ChatNuServerEndpoint.parse(String rawValue) {
    var raw = rawValue.trim();
    if (raw.isEmpty) {
      throw const FormatException('Server address is required.');
    }
    if (!raw.contains('://')) raw = 'https://$raw';
    final parsed = Uri.tryParse(raw);
    if (parsed == null || !parsed.hasAuthority || parsed.host.isEmpty) {
      throw const FormatException('Enter a valid HTTP or HTTPS server origin.');
    }
    if (parsed.scheme != 'https' && parsed.scheme != 'http') {
      throw const FormatException('Only HTTP and HTTPS servers are supported.');
    }
    if (parsed.userInfo.isNotEmpty || parsed.hasQuery) {
      throw const FormatException(
        'Server URLs cannot contain credentials or query parameters.',
      );
    }
    if (parsed.path.isNotEmpty && parsed.path != '/') {
      throw const FormatException(
        'Use the server origin only, for example https://chat.example.com.',
      );
    }

    String? pin;
    if (parsed.fragment.isNotEmpty) {
      if (!parsed.fragment.startsWith(_pinPrefix)) {
        throw const FormatException('Unsupported server enrollment fragment.');
      }
      pin = parsed.fragment.substring(_pinPrefix.length);
      if (!_validPin(pin)) {
        throw const FormatException('Invalid ChatNU emergency CA pin.');
      }
      if (parsed.scheme != 'https') {
        throw const FormatException(
          'Emergency pinned enrollment requires HTTPS.',
        );
      }
    }

    return ChatNuServerEndpoint(
      restUri: Uri(
        scheme: parsed.scheme,
        host: parsed.host,
        port: parsed.hasPort ? parsed.port : null,
        path: '/',
      ),
      tlsCaPin: pin,
    );
  }

  final Uri restUri;
  final String? tlsCaPin;

  String get restBaseUrl => restUri.toString();

  Uri get websocketUri => restUri.replace(
    scheme: restUri.scheme == 'https' ? 'wss' : 'ws',
    path: '/realtime',
  );

  String get identityNamespace {
    final port = restUri.hasPort
        ? restUri.port
        : restUri.scheme == 'https'
        ? 443
        : 80;
    return '${restUri.scheme}://${restUri.host}:$port';
  }

  String get hostLabel {
    final defaultPort = restUri.scheme == 'https' ? 443 : 80;
    final host = restUri.hasPort && restUri.port != defaultPort
        ? '${restUri.host}:${restUri.port}'
        : restUri.host;
    return tlsCaPin == null ? host : '$host · pinned';
  }

  String get enrollmentValue =>
      tlsCaPin == null ? restBaseUrl : '$restBaseUrl#$_pinPrefix$tlsCaPin';

  bool get usesEmergencyTls => tlsCaPin != null;

  static bool _validPin(String value) {
    if (!value.startsWith('sha256/')) return false;
    try {
      return base64.decode(value.substring('sha256/'.length)).length == 32;
    } on FormatException {
      return false;
    }
  }
}
