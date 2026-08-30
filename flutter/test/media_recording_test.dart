import 'package:chatnu/features/messages/presentation/recording_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatNuRecordingSession', () {
    test('hold release sends when no gesture is armed', () {
      final state = const ChatNuRecordingSession().startArming().startHolding();

      expect(state.phase, ChatNuRecordingPhase.holding);
      expect(state.releaseAction(), ChatNuRecordingReleaseAction.send);
    });

    test('slide left cancels in LTR and slide right cancels in RTL', () {
      final ltr = const ChatNuRecordingSession()
          .startArming()
          .startHolding()
          .updateHoldGesture(dx: -90, dy: 0, rtl: false);
      final rtl = const ChatNuRecordingSession()
          .startArming()
          .startHolding()
          .updateHoldGesture(dx: 90, dy: 0, rtl: true);

      expect(ltr.cancelArmed, isTrue);
      expect(rtl.cancelArmed, isTrue);
      expect(ltr.releaseAction(), ChatNuRecordingReleaseAction.cancel);
      expect(rtl.releaseAction(), ChatNuRecordingReleaseAction.cancel);
    });

    test('slide up locks and finger release keeps recording', () {
      final state = const ChatNuRecordingSession()
          .startArming()
          .startHolding()
          .updateHoldGesture(dx: -20, dy: -96, rtl: false);

      expect(state.phase, ChatNuRecordingPhase.locked);
      expect(state.lockArmed, isTrue);
      expect(state.releaseAction(), ChatNuRecordingReleaseAction.keepRecording);
    });

    test('strongest gesture wins instead of arming both actions', () {
      final lock = const ChatNuRecordingSession()
          .startArming()
          .startHolding()
          .updateHoldGesture(dx: -82, dy: -110, rtl: false);
      final cancel = const ChatNuRecordingSession()
          .startArming()
          .startHolding()
          .updateHoldGesture(dx: -110, dy: -82, rtl: false);

      expect(lock.gesture, ChatNuRecordingGesture.lock);
      expect(cancel.gesture, ChatNuRecordingGesture.cancel);
    });

    test('locked session can pause resume finish and reset', () {
      final locked = const ChatNuRecordingSession()
          .startArming()
          .startHolding()
          .updateHoldGesture(dx: 0, dy: -90, rtl: false);
      final paused = locked.pause();
      final resumed = paused.resume();
      final finishing = resumed.finish();
      final reset = finishing.reset();

      expect(paused.phase, ChatNuRecordingPhase.paused);
      expect(resumed.phase, ChatNuRecordingPhase.locked);
      expect(finishing.phase, ChatNuRecordingPhase.finishing);
      expect(reset.phase, ChatNuRecordingPhase.idle);
      expect(reset.mode, ChatNuRecordingMode.voice);
    });

    test('mode toggle is allowed only while idle', () {
      final video = const ChatNuRecordingSession().toggleMode();
      final active = video.startArming().toggleMode();

      expect(video.mode, ChatNuRecordingMode.video);
      expect(active.mode, ChatNuRecordingMode.video);
      expect(active.phase, ChatNuRecordingPhase.arming);
    });
  });
}
