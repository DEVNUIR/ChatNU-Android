import 'package:chatnu/features/calls/application/call_connection_policy.dart';
import 'package:chatnu/features/messages/application/live_location_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatNuCallConnectionPolicy', () {
    test('uses bounded ringing and reconnect grace windows', () {
      expect(
        ChatNuCallConnectionPolicy.disconnectGrace,
        const Duration(seconds: 8),
      );
      expect(
        ChatNuCallConnectionPolicy.ringingTimeout,
        const Duration(seconds: 45),
      );
    });

    test('maps microphone permission failures to user-facing copy', () {
      final message = ChatNuCallConnectionPolicy.friendlyError(
        StateError('Permission denied by microphone subsystem'),
        video: false,
      );

      expect(message, 'Microphone permission is required for voice calls.');
      expect(message, isNot(contains('StateError')));
    });

    test('maps connection failures without exposing transport details', () {
      final message = ChatNuCallConnectionPolicy.friendlyError(
        Exception('ICE connection failed on websocket transport'),
        video: true,
      );

      expect(
        message,
        'Call connection is unavailable. Check your network and try again.',
      );
      expect(message.toLowerCase(), isNot(contains('ice')));
      expect(message.toLowerCase(), isNot(contains('websocket')));
    });
  });

  group('ChatNuLiveLocationPolicy', () {
    test('is explicitly foreground-sized rather than an indefinite session', () {
      expect(
        ChatNuLiveLocationPolicy.shareDuration,
        const Duration(minutes: 15),
      );
      expect(
        ChatNuLiveLocationPolicy.updateInterval,
        const Duration(seconds: 30),
      );
    });

    test('remaining time clamps at zero after expiry', () {
      final start = DateTime.utc(2026, 8, 31, 12);
      final end = ChatNuLiveLocationPolicy.endsAt(start);

      expect(end, DateTime.utc(2026, 8, 31, 12, 15));
      expect(
        ChatNuLiveLocationPolicy.remaining(
          DateTime.utc(2026, 8, 31, 12, 5),
          end,
        ),
        const Duration(minutes: 10),
      );
      expect(
        ChatNuLiveLocationPolicy.remaining(
          DateTime.utc(2026, 8, 31, 12, 16),
          end,
        ),
        Duration.zero,
      );
    });
  });
}
