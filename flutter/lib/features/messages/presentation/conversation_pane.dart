import 'dart:async';

import 'package:chatnu/core/di/app_providers.dart';
import 'package:chatnu/core/localization/chatnu_strings.dart';
import 'package:chatnu/core/realtime/chatnu_realtime_client.dart';
import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:chatnu/features/conversations/domain/conversation.dart';
import 'package:chatnu/features/home/application/demo_messenger_controller.dart';
import 'package:chatnu/features/messages/domain/message.dart';
import 'package:chatnu/features/messages/presentation/widgets/chat_wallpaper.dart';
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
  late final TextEditingController _composerController;
  final _scrollController = ScrollController();
  bool _restoringDraft = false;

  @override
  void initState() {
    super.initState();
    _composerController = TextEditingController(
      text: ref.read(messengerDemoProvider).drafts[widget.conversationId] ?? '',
    );
    _composerController.addListener(_draftChanged);
    _scrollController.addListener(_scrollChanged);
  }

  @override
  void didUpdateWidget(covariant ConversationPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversationId == widget.conversationId) return;
    _restoreDraft(
      ref.read(messengerDemoProvider).drafts[widget.conversationId] ?? '',
    );
  }

  @override
  void dispose() {
    _composerController.removeListener(_draftChanged);
    _scrollController.removeListener(_scrollChanged);
    _composerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _draftChanged() {
    if (_restoringDraft) return;
    ref
        .read(messengerDemoProvider.notifier)
        .setDraft(widget.conversationId, _composerController.text);
  }

  void _restoreDraft(String value) {
    if (_composerController.text.isNotEmpty || value.isEmpty) return;
    _restoringDraft = true;
    _composerController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    _restoringDraft = false;
  }

  void _scrollChanged() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.maxScrollExtent - position.pixels > 280) return;
    unawaited(
      ref
          .read(messengerDemoProvider.notifier)
          .loadOlderMessages(widget.conversationId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(messengerDemoProvider);
    ref.listen<String?>(
      messengerDemoProvider.select(
        (value) => value.drafts[widget.conversationId],
      ),
      (_, next) => _restoreDraft(next ?? ''),
    );
    final animateWallpaper = ref.watch(appModeProvider) != ChatNuAppMode.demo;
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
    final loadState = state.conversationState(conversation.id);
    final visibleError = loadState.messageError ??
        (messages.isNotEmpty ? loadState.initialError : null);

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        ChatWallpaper(animate: animateWallpaper),
        SafeArea(
          child: Column(
            children: <Widget>[
              ConversationHeader(
                conversation: conversation,
                onBack: widget.onBack,
              ),
              _ConnectionNotice(
                status: state.realtimeStatus,
                syncStatus: state.syncStatus,
                onRetrySync: state.syncStatus == MessengerSyncStatus.failed
                    ? ref.read(messengerDemoProvider.notifier).retrySync
                    : null,
              ),
              if (visibleError != null)
                _InlineError(
                  message: visibleError,
                  onDismiss: () => ref
                      .read(messengerDemoProvider.notifier)
                      .clearConversationError(conversation.id),
                ),
              Expanded(
                child: messages.isEmpty
                    ? _MessageHistoryEmpty(
                        loading: loadState.initialLoading,
                        error: loadState.initialError,
                        onRetry: () => unawaited(
                          ref
                              .read(messengerDemoProvider.notifier)
                              .loadMessages(conversation.id),
                        ),
                      )
                    : ListView.builder(
                        key: const Key('message-list'),
                        controller: _scrollController,
                        reverse: true,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          14,
                          10,
                          14,
                          16,
                        ),
                        itemCount: messages.length +
                            (_showOlderStatus(loadState) ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == messages.length) {
                            return _OlderHistoryStatus(
                              state: loadState,
                              onRetry: () => unawaited(
                                ref
                                    .read(messengerDemoProvider.notifier)
                                    .loadOlderMessages(conversation.id),
                              ),
                            );
                          }
                          // With reverse:true, prepending older chronological
                          // messages does not change existing builder indices.
                          // Stable keys make that anchor explicit to Flutter.
                          final chronologicalIndex =
                              messages.length - 1 - index;
                          final message = messages[chronologicalIndex];
                          final previous = chronologicalIndex == 0
                              ? null
                              : messages[chronologicalIndex - 1];
                          final showDate =
                              previous == null ||
                              !_sameDay(previous.sentAt, message.sentAt);
                          return RepaintBoundary(
                            key: ValueKey<String>('message-row-${message.id}'),
                            child: Column(
                              children: <Widget>[
                                if (showDate)
                                  _DateSeparator(date: message.sentAt),
                                MessageBubble(
                                  message: message,
                                  mine:
                                      message.senderId == state.currentUser.id,
                                  showSender:
                                      conversation.kind ==
                                      ConversationKind.group,
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
      ],
    );
  }

  bool _showOlderStatus(ConversationLoadState state) =>
      state.loadingOlder || state.olderError != null || state.hasMore;

  bool _sameDay(DateTime a, DateTime b) {
    final localA = a.toLocal();
    final localB = b.toLocal();
    return localA.year == localB.year &&
        localA.month == localB.month &&
        localA.day == localB.day;
  }
}

class _ConnectionNotice extends StatelessWidget {
  const _ConnectionNotice({
    required this.status,
    required this.syncStatus,
    this.onRetrySync,
  });

  final RealtimeConnectionStatus status;
  final MessengerSyncStatus syncStatus;
  final Future<void> Function()? onRetrySync;

  @override
  Widget build(BuildContext context) {
    if (status == RealtimeConnectionStatus.connected &&
        syncStatus == MessengerSyncStatus.idle) {
      return const SizedBox.shrink();
    }
    final strings = ChatNuStrings.of(context);
    final palette = context.chatNu;
    final synchronizing = syncStatus == MessengerSyncStatus.synchronizing;
    final syncFailed = syncStatus == MessengerSyncStatus.failed;
    final connecting = status == RealtimeConnectionStatus.connecting;
    final busy = synchronizing || connecting;
    final label = synchronizing
        ? strings.syncingMessages
        : syncFailed
        ? strings.syncFailed
        : connecting
        ? strings.realtimeConnecting
        : strings.realtimeDisconnected;
    final content = Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 32),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      color: busy
          ? palette.glassWeak.withValues(alpha: 0.82)
          : palette.warning.withValues(alpha: 0.11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (busy)
            const SizedBox.square(
              dimension: 12,
              child: CircularProgressIndicator(strokeWidth: 1.3),
            )
          else
            Icon(Icons.cloud_off_outlined, size: 14, color: palette.warning),
          const SizedBox(width: 7),
          Flexible(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
    return Semantics(
      liveRegion: true,
      button: onRetrySync != null,
      child: onRetrySync == null
          ? content
          : InkWell(
              onTap: () => unawaited(onRetrySync!()),
              child: content,
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

class _OlderHistoryStatus extends StatelessWidget {
  const _OlderHistoryStatus({required this.state, required this.onRetry});

  final ConversationLoadState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final strings = ChatNuStrings.of(context);
    if (state.loadingOlder) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Center(
          child: SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 1.8),
          ),
        ),
      );
    }
    if (state.olderError != null) {
      return Center(
        child: TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: Text(strings.retryOlderMessages),
        ),
      );
    }
    return const SizedBox(height: 12);
  }
}

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final local = date.toLocal();
    final text = MaterialLocalizations.of(context).formatMediumDate(local);
    final palette = context.chatNu;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: palette.backgroundElevated.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: palette.borderSubtle),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ),
      ),
    );
  }
}

class _MessageHistoryEmpty extends StatelessWidget {
  const _MessageHistoryEmpty({
    required this.loading,
    required this.error,
    required this.onRetry,
  });

  final bool loading;
  final String? error;
  final VoidCallback onRetry;

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
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.error_outline_rounded,
                color: palette.destructive,
                size: 30,
              ),
              const SizedBox(height: 10),
              Text(
                strings.couldNotLoadConversation,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              OutlinedButton(onPressed: onRetry, child: Text(strings.retry)),
            ],
          ),
        ),
      );
    }
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: palette.backgroundElevated.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: palette.borderSubtle),
        ),
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
