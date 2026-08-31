import 'dart:async';

import 'package:chatnu/core/di/app_providers.dart';
import 'package:chatnu/features/home/application/demo_messenger_controller.dart';
import 'package:chatnu/features/messages/application/live_location_policy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

enum ChatNuLiveLocationStatus { idle, starting, sharing, failed }

class ChatNuLiveLocationState {
  const ChatNuLiveLocationState({
    this.status = ChatNuLiveLocationStatus.idle,
    this.conversationId,
    this.startedAt,
    this.endsAt,
    this.lastSentAt,
    this.latitude,
    this.longitude,
    this.error,
  });

  final ChatNuLiveLocationStatus status;
  final String? conversationId;
  final DateTime? startedAt;
  final DateTime? endsAt;
  final DateTime? lastSentAt;
  final double? latitude;
  final double? longitude;
  final String? error;

  bool get isSharing => status == ChatNuLiveLocationStatus.sharing;

  bool isSharingConversation(String id) => isSharing && conversationId == id;

  Duration remaining(DateTime now) {
    final end = endsAt;
    if (end == null) return Duration.zero;
    return ChatNuLiveLocationPolicy.remaining(now, end);
  }

  ChatNuLiveLocationState copyWith({
    ChatNuLiveLocationStatus? status,
    String? conversationId,
    DateTime? startedAt,
    DateTime? endsAt,
    DateTime? lastSentAt,
    double? latitude,
    double? longitude,
    String? error,
    bool clearError = false,
  }) {
    return ChatNuLiveLocationState(
      status: status ?? this.status,
      conversationId: conversationId ?? this.conversationId,
      startedAt: startedAt ?? this.startedAt,
      endsAt: endsAt ?? this.endsAt,
      lastSentAt: lastSentAt ?? this.lastSentAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class LiveLocationController extends Notifier<ChatNuLiveLocationState> {
  Timer? _timer;
  bool _sending = false;

  @override
  ChatNuLiveLocationState build() {
    ref.onDispose(() => _timer?.cancel());
    return const ChatNuLiveLocationState();
  }

  Future<void> start(String conversationId) async {
    if (ref.read(appModeProvider) == ChatNuAppMode.demo) return;
    if (state.isSharingConversation(conversationId)) return;

    stop();
    state = ChatNuLiveLocationState(
      status: ChatNuLiveLocationStatus.starting,
      conversationId: conversationId,
    );

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError('Location services are turned off.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError(
          'Location permission is required to share Live Location.',
        );
      }

      final startedAt = DateTime.now();
      state = ChatNuLiveLocationState(
        status: ChatNuLiveLocationStatus.sharing,
        conversationId: conversationId,
        startedAt: startedAt,
        endsAt: ChatNuLiveLocationPolicy.endsAt(startedAt),
      );

      await _sendUpdate();
      if (!state.isSharingConversation(conversationId)) return;
      _timer = Timer.periodic(ChatNuLiveLocationPolicy.updateInterval, (_) {
        unawaited(_sendUpdate());
      });
    } catch (error) {
      _timer?.cancel();
      _timer = null;
      state = ChatNuLiveLocationState(
        status: ChatNuLiveLocationStatus.failed,
        conversationId: conversationId,
        error: _friendlyError(error),
      );
    }
  }

  Future<void> _sendUpdate() async {
    if (_sending || !state.isSharing) return;
    final conversationId = state.conversationId;
    final endsAt = state.endsAt;
    if (conversationId == null || endsAt == null) return;
    if (ChatNuLiveLocationPolicy.isExpired(DateTime.now(), endsAt)) {
      stop();
      return;
    }

    _sending = true;
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: ChatNuLiveLocationPolicy.fixTimeout,
        ),
      );
      final repository = ref.read(messengerRepositoryProvider);
      final clientId = repository.newClientId();
      await repository.sendLocation(
        conversationId: conversationId,
        clientId: clientId,
        latitude: position.latitude,
        longitude: position.longitude,
        label: 'Live location',
        live: true,
      );
      await ref
          .read(messengerDemoProvider.notifier)
          .loadMessages(conversationId);
      if (!state.isSharingConversation(conversationId)) return;
      state = state.copyWith(
        lastSentAt: DateTime.now(),
        latitude: position.latitude,
        longitude: position.longitude,
        clearError: true,
      );
    } catch (error) {
      if (!state.isSharingConversation(conversationId)) return;
      state = state.copyWith(error: _friendlyError(error));
    } finally {
      _sending = false;
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _sending = false;
    state = const ChatNuLiveLocationState();
  }

  String _friendlyError(Object error) {
    final raw = error
        .toString()
        .replaceFirst('Bad state: ', '')
        .replaceFirst('StateError: ', '');
    final lower = raw.toLowerCase();
    if (lower.contains('permission')) {
      return 'Location permission is required to share Live Location.';
    }
    if (lower.contains('service') || lower.contains('location')) {
      if (lower.contains('off') || lower.contains('disabled')) {
        return 'Turn on Location Services to continue sharing.';
      }
    }
    if (lower.contains('network') || lower.contains('connection')) {
      return 'Live Location could not update. Check your connection.';
    }
    return raw.isEmpty ? 'Live Location could not update.' : raw;
  }
}

final liveLocationControllerProvider =
    NotifierProvider<LiveLocationController, ChatNuLiveLocationState>(
      LiveLocationController.new,
    );
