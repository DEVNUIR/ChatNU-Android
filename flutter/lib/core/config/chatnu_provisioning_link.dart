import 'package:chatnu/core/config/server_endpoint.dart';

enum ChatNuProvisioningKind { server }

class ChatNuProvisioningLink {
  const ChatNuProvisioningLink({
    required this.kind,
    required this.version,
    required this.endpoint,
    this.name,
  });

  static const currentVersion = 1;
  static const scheme = 'chatnu';

  final ChatNuProvisioningKind kind;
  final int version;
  final ChatNuServerEndpoint endpoint;
  final String? name;

  factory ChatNuProvisioningLink.parse(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null || uri.scheme.toLowerCase() != scheme) {
      throw const FormatException('Not a ChatNU provisioning link.');
    }
    if (uri.userInfo.isNotEmpty || uri.fragment.isNotEmpty) {
      throw const FormatException(
        'ChatNU provisioning links cannot contain credentials or fragments.',
      );
    }
    if (uri.host.toLowerCase() != 'server' || uri.path != '/add') {
      throw const FormatException('Unsupported ChatNU provisioning action.');
    }

    const allowed = <String>{'v', 'url', 'name', 'pin'};
    final unexpected = uri.queryParameters.keys.where(
      (key) => !allowed.contains(key),
    );
    if (unexpected.isNotEmpty) {
      throw FormatException(
        'Unsupported ChatNU provisioning field: ${unexpected.first}',
      );
    }

    final version = int.tryParse(uri.queryParameters['v'] ?? '');
    if (version == null || version != currentVersion) {
      throw const FormatException('Unsupported ChatNU provisioning version.');
    }
    final rawUrl = uri.queryParameters['url']?.trim() ?? '';
    if (rawUrl.isEmpty) {
      throw const FormatException('ChatNU server URL is required.');
    }
    final rawPin = uri.queryParameters['pin']?.trim();
    final enrollment = rawPin == null || rawPin.isEmpty
        ? rawUrl
        : '$rawUrl#chatnu-ca=$rawPin';
    final endpoint = ChatNuServerEndpoint.parse(enrollment);
    if (endpoint.restUri.scheme != 'https') {
      throw const FormatException(
        'QR/deep-link server enrollment requires HTTPS.',
      );
    }

    final rawName = uri.queryParameters['name']?.trim();
    final name = rawName == null || rawName.isEmpty ? null : rawName;
    if (name != null && name.length > 80) {
      throw const FormatException('Server name is too long.');
    }

    return ChatNuProvisioningLink(
      kind: ChatNuProvisioningKind.server,
      version: version,
      endpoint: endpoint,
      name: name,
    );
  }

  Uri toUri() {
    final query = <String, String>{
      'v': version.toString(),
      'url': endpoint.restBaseUrl,
      if (name?.trim().isNotEmpty == true) 'name': name!.trim(),
      if (endpoint.tlsCaPin != null) 'pin': endpoint.tlsCaPin!,
    };
    return Uri(
      scheme: scheme,
      host: 'server',
      path: '/add',
      queryParameters: query,
    );
  }

  String get qrData => toUri().toString();
}
