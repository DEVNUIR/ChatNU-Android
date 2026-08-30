import 'dart:async';

import 'package:chatnu/core/di/app_providers.dart';
import 'package:chatnu/core/glass/glass_components.dart';
import 'package:chatnu/core/localization/chatnu_strings.dart';
import 'package:chatnu/core/realtime/chatnu_realtime_client.dart';
import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:chatnu/features/conversations/domain/conversation.dart';
import 'package:chatnu/features/home/application/demo_messenger_controller.dart';
import 'package:chatnu/features/messages/domain/message.dart';
import 'package:chatnu/features/messages/presentation/message_grouping.dart';
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
    this.groupingGap = MessageGrouping.defaultGap,
  });

  final String conversationId;
  final VoidCallback? onBack;
  final Duration groupingGap;

  @override
  ConsumerState<ConversationPane> createState() => _ConversationPaneState();
}

class _ConversationPaneState extends ConsumerState<ConversationPane> {
  late final TextEditingController _composerController;
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  final _scrollController = ScrollController();
  final Map<String, GlobalKey> _messageKeys = <String, GlobalKey>{};

  bool _restoringDraft = false;
  bool _searchOpen = false;
  bool _showJumpToBottom = false;
  int _newMessagesBelow = 0;
  String? _newMessageMarkerId;
  String? _activeSearchMessageId;

  @override
  void initState() {
    super.initState();
    _composerController = TextEditingController(
      text: ref.read(messengerDemoProvider).drafts[widget.conversationId] ?? '',
    );
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _composerController.addListener(_draftChanged);
    _scrollController.addListener(_scrollChanged);
  }

  @override
  void didUpdateWidget(covariant ConversationPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversationId == widget.conversationId) return;
    _searchOpen = false;
    _searchController.clear();
    _activeSearchMessageId = null;
    _newMessagesBelow = 0;
    _newMessageMarkerId = null;
    _showJumpToBottom = false;
    _messageKeys.clear();
    _restoreDraft(
      ref.read(messengerDemoProvider).drafts[widget.conversationId] ?? '',
      force: true,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(animated: false);
    });
  }

  @override
  void dispose() {
    _composerController.removeListener(_draftChanged);
    _scrollController.removeListener(_scrollChanged);
    _composerController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _draftChanged() {
    if (_restoringDraft) return;
    ref
        .read(messengerDemoProvider.notifier)
        .setDraft(widget.conversationId, _composerController.text);
  }

  void _restoreDraft(String value, {bool force = false}) {
    if (_composerController.text == value) return;
    if (!force && _composerController.text.isNotEmpty) return;
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
    final showJump = position.pixels > 180;
    final reachedBottom = position.pixels <= 72;
    if (showJump != _showJumpToBottom ||
        (reachedBottom && _newMessagesBelow > 0)) {
      setState(() {
        _showJumpToBottom = showJump;
        if (reachedBottom) {
          _newMessagesBelow = 0;
          _newMessageMarkerId = null;
        }
      });
    }
    if (position.maxScrollExtent - position.pixels > 280) return;
    unawaited(
      ref
          .read(messengerDemoProvider.notifier)
          .loadOlderMessages(widget.conversationId),
    );
  }

  void _handleMessageChanges(
    List<ChatNuMessage> previous,
    List<ChatNuMessage> next,
  ) {
    if (!mounted || previous.isEmpty || next.isEmpty) return;
    final previousIds = previous.map(_messageIdentity).toSet();
    final previousNewestAt = previous.last.sentAt;
    final added = next
        .where((message) => !previousIds.contains(_messageIdentity(message)))
        .where((message) => !message.sentAt.isBefore(previousNewestAt))
        .toList(growable: false);
    if (added.isEmpty) return;

    final currentUserId = ref.read(messengerDemoProvider).currentUser.id;
    final ownMessageAdded = added.any(
      (message) => message.senderId == currentUserId,
    );
    final incoming = added
        .where((message) => message.senderId != currentUserId)
        .toList(growable: false);
    final followLatest = !_searchOpen && (_isNearBottom || ownMessageAdded);

    if (followLatest) {
      if (_newMessagesBelow > 0 || _newMessageMarkerId != null) {
        setState(() {
          _newMessagesBelow = 0;
          _newMessageMarkerId = null;
        });
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom(animated: true);
      });
      return;
    }

    if (incoming.isNotEmpty) {
      setState(() {
        _newMessagesBelow += incoming.length;
        _newMessageMarkerId ??= incoming.first.id;
        _showJumpToBottom = true;
      });
    }
  }

  bool get _isNearBottom =>
      !_scrollController.hasClients || _scrollController.position.pixels <= 96;

  String _messageIdentity(ChatNuMessage message) =>
      message.clientId == null || message.clientId!.isEmpty
      ? 'id:${message.id}'
      : 'client:${message.clientId}';

  void _scrollToBottom({required bool animated}) {
    if (!mounted || !_scrollController.hasClients) return;
    if (!animated || MediaQuery.disableAnimationsOf(context)) {
      _scrollController.jumpTo(_scrollController.position.minScrollExtent);
      return;
    }
    unawaited(
      _scrollController.animateTo(
        _scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 190),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  void _toggleSearch() {
    setState(() {
      _searchOpen = !_searchOpen;
      _activeSearchMessageId = null;
      if (!_searchOpen) _searchController.clear();
    });
    if (_searchOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocusNode.requestFocus();
      });
    } else {
      _searchFocusNode.unfocus();
    }
  }

  void _onSearchChanged(String value) {
    final messages =
        ref
            .read(messengerDemoProvider)
            .messagesByConversation[widget.conversationId] ??
        const <ChatNuMessage>[];
    final matches = _searchMatches(messages, query: value);
    final nextId = matches.isEmpty ? null : matches.last.id;
    setState(() => _activeSearchMessageId = nextId);
    if (nextId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToMessage(nextId);
      });
    }
  }

  void _navigateSearch({required bool older}) {
    final messages =
        ref
            .read(messengerDemoProvider)
            .messagesByConversation[widget.conversationId] ??
        const <ChatNuMessage>[];
    final matches = _searchMatches(messages);
    if (matches.isEmpty) return;
    var index = matches.indexWhere(
      (message) => message.id == _activeSearchMessageId,
    );
    if (index < 0) index = matches.length - 1;
    final targetIndex = older
        ? (index - 1).clamp(0, matches.length - 1)
        : (index + 1).clamp(0, matches.length - 1);
    final targetId = matches[targetIndex].id;
    if (targetId == _activeSearchMessageId) return;
    setState(() => _activeSearchMessageId = targetId);
    _scrollToMessage(targetId);
  }

  List<ChatNuMessage> _searchMatches(
    List<ChatNuMessage> messages, {
    String? query,
  }) {
    final needle = (query ?? _searchController.text).trim().toLowerCase();
    if (needle.isEmpty) return const <ChatNuMessage>[];
    return messages
        .where((message) => _searchableText(message).contains(needle))
        .toList(growable: false);
  }

  String _searchableText(ChatNuMessage message) {
    return <String>[
      message.body,
      message.senderName,
      if (message.fileName != null) message.fileName!,
    ].join('\n').toLowerCase();
  }

  void _scrollToMessage(String messageId) {
    if (!mounted) return;
    final messages =
        ref
            .read(messengerDemoProvider)
            .messagesByConversation[widget.conversationId] ??
        const <ChatNuMessage>[];
    final chronologicalIndex = messages.indexWhere(
      (message) => message.id == messageId,
    );
    if (chronologicalIndex < 0) return;
    if (!_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToMessage(messageId);
      });
      return;
    }

    final reverseIndex = messages.length - 1 - chronologicalIndex;
    final position = _scrollController.position;
    final target = messages.length <= 1
        ? position.minScrollExtent
        : position.maxScrollExtent * (reverseIndex / (messages.length - 1));
    final clamped = target.clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    final future = MediaQuery.disableAnimationsOf(context)
        ? Future<void>.sync(() => _scrollController.jumpTo(clamped.toDouble()))
        : _scrollController.animateTo(
            clamped.toDouble(),
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
          );
    unawaited(
      future.then((_) async {
        if (!mounted) return;
        await WidgetsBinding.instance.endOfFrame;
        final targetContext = _messageKeys[messageId]?.currentContext;
        if (targetContext == null) return;
        await Scrollable.ensureVisible(
          targetContext,
          alignment: 0.45,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
        );
      }),
    );
  }

  GlobalKey _messageKey(String messageId) =>
      _messageKeys.putIfAbsent(messageId, GlobalKey.new);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(messengerDemoProvider);
    ref.listen<String?>(
      messengerDemoProvider.select(
        (value) => value.drafts[widget.conversationId],
      ),
      (_, next) => _restoreDraft(next ?? ''),
    );
    ref.listen<List<ChatNuMessage>>(
      messengerDemoProvider.select(
        (value) =>
            value.messagesByConversation[widget.conversationId] ??
            const <ChatNuMessage>[],
      ),
      (previous, next) =>
          _handleMessageChanges(previous ?? const <ChatNuMessage>[], next),
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
    final visibleError =
        loadState.messageError ??
        (messages.isNotEmpty ? loadState.initialError : null);
    final strings = ChatNuStrings.of(context);
    final searchMatches = _searchMatches(messages);
    final activeSearchIndex = searchMatches.indexWhere(
      (message) => message.id == _activeSearchMessageId,
    );
    final searchResultLabel = !_searchOpen || _searchController.text.trim().isEmpty
        ? null
        : searchMatches.isEmpty
        ? strings.noMessageMatches
        : strings.messageSearchResult(
            activeSearchIndex < 0 ? searchMatches.length : activeSearchIndex + 1,
            searchMatches.length,
          );

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
                searchOpen: _searchOpen,
                searchController: _searchController,
                searchFocusNode: _searchFocusNode,
                searchResultLabel: searchResultLabel,
                onSearchChanged: _onSearchChanged,
                onSearchToggle: _toggleSearch,
                onPreviousSearchResult:
                    activeSearchIndex > 0 ? () => _navigateSearch(older: true) : null,
                onNextSearchResult:
                    activeSearchIndex >= 0 &&
                        activeSearchIndex < searchMatches.length - 1
                    ? () => _navigateSearch(older: false)
                    : null,
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
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(
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
                              itemCount:
                                  messages.length +
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
                                final mine =
                                    message.senderId == state.currentUser.id;
                                final groupPosition = MessageGrouping.positionAt(
                                  messages,
                                  chronologicalIndex,
                                  gap: widget.groupingGap,
                                );
                                final groupStart =
                                    MessageGrouping.isGroupStart(groupPosition);
                                final member = conversation.members
                                    .where(
                                      (user) => user.id == message.senderId,
                                    )
                                    .firstOrNull;
                                final groupConversation =
                                    conversation.kind == ConversationKind.group;
                                final showSender =
                                    groupConversation && !mine && groupStart;
                                final newMessageMarker =
                                    _newMessageMarkerId == message.id &&
                                    _newMessagesBelow > 0;
                                return RepaintBoundary(
                                  key: ValueKey<String>(
                                    'message-row-${message.id}',
                                  ),
                                  child: Container(
                                    key: _messageKey(message.id),
                                    child: Column(
                                      children: <Widget>[
                                        if (showDate)
                                          _DateSeparator(date: message.sentAt),
                                        if (newMessageMarker)
                                          _NewMessagesSeparator(
                                            count: _newMessagesBelow,
                                          ),
                                        MessageBubble(
                                          message: message,
                                          mine: mine,
                                          showSender: showSender,
                                          groupPosition: groupPosition,
                                          senderAvatarUrl: member?.avatarUrl,
                                          showAvatar: showSender,
                                          reserveAvatarSpace:
                                              groupConversation && !mine,
                                          searchQuery: _searchOpen
                                              ? _searchController.text
                                              : '',
                                          searchSelected:
                                              _searchOpen &&
                                              _activeSearchMessageId ==
                                                  message.id,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    if (_showJumpToBottom || _newMessagesBelow > 0)
                      PositionedDirectional(
                        end: 12,
                        bottom: 12,
                        child: _ScrollToBottomButton(
                          count: _newMessagesBelow,
                          onTap: () {
                            setState(() {
                              _newMessagesBelow = 0;
                              _newMessageMarkerId = null;
                              _showJumpToBottom = false;
                            });
                            _scrollToBottom(animated: true);
                          },
                        ),
                      ),
                  ],
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
          : InkWell(onTap: () => unawaited(onRetrySync!()), child: content),
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

class _NewMessagesSeparator extends StatelessWidget {
  const _NewMessagesSeparator({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final strings = ChatNuStrings.of(context);
    final palette = context.chatNu;
    return Semantics(
      liveRegion: true,
      label: strings.newMessages(count),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: <Widget>[
            Expanded(child: Divider(color: palette.accentPrimary)),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 9),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: palette.backgroundElevated.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: palette.accentPrimary.withValues(alpha: 0.58),
                ),
              ),
              child: Text(
                strings.newMessages(count),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(child: Divider(color: palette.accentPrimary)),
          ],
        ),
      ),
    );
  }
}

class _ScrollToBottomButton extends StatelessWidget {
  const _ScrollToBottomButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = ChatNuStrings.of(context);
    final palette = context.chatNu;
    final semanticLabel = count > 0
        ? strings.newMessages(count)
        : strings.scrollToLatest;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Material(
            color: palette.backgroundElevated.withValues(alpha: 0.94),
            shape: CircleBorder(
              side: BorderSide(color: palette.borderHighlight),
            ),
            elevation: 4,
            child: InkWell(
              key: const Key('scroll-to-latest-button'),
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: const SizedBox.square(
                dimension: 48,
                child: Icon(Icons.keyboard_arrow_down_rounded, size: 27),
              ),
            ),
          ),
          if (count > 0)
            PositionedDirectional(
              top: -7,
              end: -7,
              child: GlassBadge(
                label: count > 99 ? '99+' : '$count',
                semanticLabel: strings.newMessages(count),
              ),
            ),
        ],
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
