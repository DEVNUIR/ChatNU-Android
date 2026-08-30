import 'package:chatnu/features/messages/application/live_location_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LiveLocationLifecycleGuard extends ConsumerStatefulWidget {
  const LiveLocationLifecycleGuard({super.key});

  @override
  ConsumerState<LiveLocationLifecycleGuard> createState() =>
      _LiveLocationLifecycleGuardState();
}

class _LiveLocationLifecycleGuardState
    extends ConsumerState<LiveLocationLifecycleGuard>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) return;
    ref.read(liveLocationControllerProvider.notifier).stop();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
