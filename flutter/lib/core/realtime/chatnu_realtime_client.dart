import 'dart:async';
import 'dart:convert';

import 'package:chatnu/core/config/server_endpoint.dart';
import 'package:chatnu/core/storage/credential_vault.dart';
import 'package:web_socket_channel/io.dart';

enum RealtimeConnectionStatus { disconnected, connecting, connected }

class ChatNuRealtimeClient {
  factory ChatNuRealtimeClient({
    required ChatNuServerEndpoint endpoint,
    required CredentialVault vault,
  }) {
    final key = '${endpoint.restBaseUrl}|${identityHashCode(vault)}';
    return _instances.putIfAbsent(
      key,
      () => ChatNuRealtimeClient._(endpoint: endpoint, vault: vault),
    );
  }

  ChatNuRealtimeClient._({
    required ChatNuServerEndpoint endpoint,
    required CredentialVault vault,
  }) : _endpoint = endpoint,
       _vault = vault;

  static final Map<String, ChatNuRealtimeClient> _instances =
      <String, ChatNuRealtimeClient>{};

  final ChatNuServerEndpoint _endpoint;
  final CredentialVault _vault;
  final StreamController<Map<String, dynamic>> _events =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<RealtimeConnectionStatus> _status =
      StreamController<RealtimeConnectionStatus>.broadcast();

  IOWebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  bool _stopped = true;
  int _attempt = 0;

  Stream<Map<String, dynamic>> get events => _events.stream;
  Stream<RealtimeConnectionStatus> get status => _status.stream;

  Future<void> start() async {
    _stopped = false;
    await _connect();
  }

  Future<void> _connect() async {
    if (_stopped || _channel != null) return;
    final token = _vault.accessToken;
    if (token == null || token.isEmpty) {
      _status.add(RealtimeConnectionStatus.disconnected);
      return;
    }
    if (_endpoint.usesEmergencyTls) {
      _status.add(RealtimeConnectionStatus.disconnected);
      return;
    }

    _status.add(RealtimeConnectionStatus.connecting);
    final channel = IOWebSocketChannel.connect(
      _endpoint.websocketUri,
      headers: <String, dynamic>{'Authorization': 'Bearer $token'},
      pingInterval: const Duration(seconds: 25),
      connectTimeout: const Duration(seconds: 15),
    );
    _channel = channel;
    try {
      await channel.ready;
      if (_stopped) {
        await channel.sink.close(1000, 'stopped');
        return;
      }
      _attempt = 0;
      _status.add(RealtimeConnectionStatus.connected);
      _subscription = channel.stream.listen(
        _handleMessage,
        onDone: _handleDisconnect,
        onError: (_) => _handleDisconnect(),
        cancelOnError: true,
      );
    } catch (_) {
      _channel = null;
      _status.add(RealtimeConnectionStatus.disconnected);
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic raw) {
    if (raw is! String) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        _events.add(
          decoded.map((key, value) => MapEntry(key.toString(), value)),
        );
      }
    } on FormatException {
      // Ignore malformed realtime payloads rather than crashing the stream.
    }
  }

  void _handleDisconnect() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    _channel = null;
    _status.add(RealtimeConnectionStatus.disconnected);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_stopped || _reconnectTimer != null) return;
    _attempt = (_attempt + 1).clamp(1, 6).toInt();
    final seconds = (1 << (_attempt - 1)).clamp(3, 30).toInt();
    _reconnectTimer = Timer(Duration(seconds: seconds), () {
      _reconnectTimer = null;
      unawaited(_connect());
    });
  }

  bool send(Map<String, dynamic> event) {
    final channel = _channel;
    if (channel == null) return false;
    channel.sink.add(jsonEncode(event));
    return true;
  }

  Future<void> stop() async {
    _stopped = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _subscription?.cancel();
    _subscription = null;
    final channel = _channel;
    _channel = null;
    if (channel != null) await channel.sink.close(1000, 'logout');
    _status.add(RealtimeConnectionStatus.disconnected);
  }
}
