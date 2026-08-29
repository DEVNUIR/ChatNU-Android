import 'package:chatnu/core/localization/chatnu_strings.dart';
import 'package:chatnu/core/realtime/chatnu_realtime_client.dart';
import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:chatnu/features/conversations/domain/conversation.dart';
import 'package:chatnu/features/home/application/demo_messenger_controller.dart';
import 'package:chatnu/features/messages/domain/message.dart';
import 'package:chatnu/features/messages/presentation/widgets/conversation_header.dart';
import 'package:chatnu/features/messages/presentation/widgets/message_bubble.dart';
import 'package:chatnu/features/messages/presentation/widgets/message_composer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConversationPane extends ConsumerStatefulWidget {
  const ConversationPane({
    required this.conversationId,
    super.key,
    this.onBack,
  });

  final String conversationId;
  final VoidCallback? onBack;

  @override
  ConsumerState<ConversationPane> createState() => _ConversationPaneState();
}

class _ConversationPaneState extends ConsumerState<ConversationPane> {
  final _composerController = TextEditingController();

  @override
  void dispose() {
    _composerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    final state = ref.watch(messengerDemoProvider);
    final conversation = state.conversations
        .where((item) => item.id == widget.conversationId)
        .firstOrNull;
    if (conversation == null) {
      return const Center(
        child: SizedBox.square(
          dimension: 28,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    final messages =
        state.messagesByConversation[conversation.id] ??
        const <ChatNuMessage>[];

    return ColoredBox(
      color: palette.backgroundSecondary,
      child: SafeArea(
        child: Column(
          children: <Widget>[
            ConversationHeader(
              conversation: conversation,
              onBack: widget.onBack,
            ),
            _ConnectionNotice(status: state.realtimeStatus),
            if (state.error != null)
              _InlineError(
                message: state.error!,
                onDismiss: ref.read(messengerDemoProvider.notifier).clearError,
              ),
            Expanded(
              child: messages.isEmpty
                  ? _MessageHistoryEmpty(loading: state.isLoading)
                  : ListView.builder(
                      key: const Key('message-list'),
                      reverse: true,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        14,
                        10,
                        14,
                        16,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final chronologicalIndex = messages.length - 1 - index;
                        final message = messages[chronologicalIndex];
                        final previous = chronologicalIndex == 0
                            ? null
                            : messages[chronologicalIndex - 1];
                        final showDate =
                            previous == null ||
                            !_sameDay(previous.sentAt, message.sentAt);
                        return RepaintBoundary(
                          child: Column(
                            children: <Widget>[
                              if (showDate)
                                _DateSeparator(date: message.sentAt),
                              MessageBubble(
                                message: message,
                                mine: message.senderId == state.currentUser.id,
                                showSender:
                                    conversation.kind == ConversationKind.group,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            MessageComposer(
              controller: _composerController,
              conversationId: conversation.id,
            ),
          ],
        ),
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) {
    final localA = a.toLocal();
    final localB = b.toLocal();
    return localA.year == localB.year &&
        localA.month == localB.month &&
        localA.day == localB.day;
  }
}

class _ConnectionNotice extends StatelessWidget {
  const _ConnectionNotice({required this.status});

  final RealtimeConnectionStatus status;

  @override
  Widget build(BuildContext context) {
    if (status == RealtimeConnectionStatus.connected) {
      return const SizedBox.shrink();
    }
    final strings = ChatNuStrings.of(context);
    final palette = context.chatNu;
    final connecting = status == RealtimeConnectionStatus.connecting;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        color: connecting
            ? palette.glassWeak
            : palette.warning.withValues(alpha: 0.11),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (connecting)
              const SizedBox.square(
                dimension: 12,
                child: CircularProgressIndicator(strokeWidth: 1.3),
              )
            else
              Icon(Icons.cloud_off_outlined, size: 14, color: palette.warning),
            const SizedBox(width: 7),
            Text(
              connecting
                  ? strings.realtimeConnecting
                  : strings.realtimeDisconnected,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final strings = ChatNuStrings.of(context);
    final palette = context.chatNu;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 7, 6, 7),
        color: palette.destructive.withValues(alpha: 0.08),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.error_outline_rounded,
              size: 17,
              color: palette.destructive,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            IconButton(
              tooltip: strings.dismiss,
              onPressed: onDismiss,
              icon: const Icon(Icons.close_rounded, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final local = date.toLocal();
    final text = MaterialLocalizations.of(context).formatMediumDate(local);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Text(text, style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }
}

class _MessageHistoryEmpty extends StatelessWidget {
  const _MessageHistoryEmpty({required this.loading});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    final strings = ChatNuStrings.of(context);
    final palette = context.chatNu;
    if (loading) {
      return const Center(
        child: SizedBox.square(
          dimension: 28,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.lock_outline_rounded,
              size: 28,
              color: palette.textMuted,
            ),
            const SizedBox(height: 10),
            Text(
              strings.encrypted,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 3),
            Text(
              strings.secureMessaging,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
