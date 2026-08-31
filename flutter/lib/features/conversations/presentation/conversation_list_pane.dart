import 'dart:async';

import 'package:chatnu/core/localization/chatnu_strings.dart';
import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:chatnu/features/contacts/presentation/new_chat_sheet.dart';
import 'package:chatnu/features/conversations/domain/conversation.dart';
import 'package:chatnu/features/home/application/demo_messenger_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _ConversationAction { pin, mute }

class ConversationListPane extends ConsumerStatefulWidget {
  const ConversationListPane({
    required this.onSelected,
    this.showComposeAction = false,
    super.key,
  });

  final ValueChanged<String> onSelected;
  final bool showComposeAction;

  @override
  ConsumerState<ConversationListPane> createState() =>
      _ConversationListPaneState();
}

class _ConversationListPaneState extends ConsumerState<ConversationListPane> {
  final _searchController = TextEditingController();
  bool _searching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ChatNuStrings.of(context);
    final state = ref.watch(messengerDemoProvider);
    final query = _searchController.text.trim().toLowerCase();
    final conversations = state.conversations
        .where((conversation) {
          final draft =
              state.drafts[conversation.id]?.trim().toLowerCase() ?? '';
          return query.isEmpty ||
              conversation.title.toLowerCase().contains(query) ||
              conversation.lastMessagePreview.toLowerCase().contains(query) ||
              draft.contains(query);
        })
        .toList(growable: false);
    final recent = state.conversations
        .where((item) => item.kind == ConversationKind.direct)
        .take(6)
        .toList(growable: false);

    return ColoredBox(
      color: Colors.transparent,
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: ref
              .read(messengerDemoProvider.notifier)
              .refreshConversations,
          child: CustomScrollView(
            key: const Key('conversation-list'),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 14, 14, 0),
                  child: _searching
                      ? _SearchHeader(
                          controller: _searchController,
                          hintText: strings.searchConversations,
                          onChanged: (_) => setState(() {}),
                          onClose: () {
                            setState(() {
                              _searching = false;
                              _searchController.clear();
                            });
                          },
                        )
                      : Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                strings.appName,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontSize: 27),
                              ),
                            ),
                            IconButton(
                              key: const Key('conversation-search-button'),
                              tooltip: strings.searchConversations,
                              onPressed: () =>
                                  setState(() => _searching = true),
                              icon: const Icon(Icons.search_rounded, size: 28),
                            ),
                            if (widget.showComposeAction)
                              IconButton(
                                key: const Key('conversation-list-compose'),
                                tooltip: strings.newChat,
                                onPressed: () =>
                                    unawaited(showNewChatSheet(context)),
                                icon: const Icon(Icons.edit_rounded, size: 25),
                              ),
                          ],
                        ),
                ),
              ),
              if (!_searching && recent.isNotEmpty)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 108,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        20,
                        16,
                        20,
                        8,
                      ),
                      itemCount: recent.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        final conversation = recent[index];
                        return _RecentPerson(
                          conversation: conversation,
                          onTap: () => widget.onSelected(conversation.id),
                        );
                      },
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    20,
                    _searching ? 24 : 14,
                    14,
                    8,
                  ),
                  child: Text(
                    strings.chats,
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(fontSize: 21),
                  ),
                ),
              ),
              if (conversations.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _ConversationEmptyState(
                    filtered: query.isNotEmpty,
                    onStart: () => unawaited(showNewChatSheet(context)),
                  ),
                )
              else
                SliverList.builder(
                  itemCount: conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = conversations[index];
                    return RepaintBoundary(
                      child: _ConversationTile(
                        conversation: conversation,
                        draft: state.drafts[conversation.id],
                        selected:
                            conversation.id == state.selectedConversationId,
                        onTap: () => widget.onSelected(conversation.id),
                        onContextMenu: (position) => _showConversationMenu(
                          context,
                          conversation,
                          globalPosition: position,
                        ),
                      ),
                    );
                  },
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showConversationMenu(
    BuildContext context,
    ChatNuConversation conversation, {
    Offset? globalPosition,
  }) async {
    final strings = ChatNuStrings.of(context);
    final pinLabel = conversation.isPinned ? strings.unpin : strings.pin;
    final muteLabel = conversation.isMuted ? strings.unmute : strings.mute;

    if (globalPosition != null) {
      final overlay = Overlay.of(context).context.findRenderObject();
      if (overlay is RenderBox) {
        final selected = await showMenu<_ConversationAction>(
          context: context,
          position: RelativeRect.fromRect(
            Rect.fromPoints(globalPosition, globalPosition),
            Offset.zero & overlay.size,
          ),
          items: <PopupMenuEntry<_ConversationAction>>[
            PopupMenuItem<_ConversationAction>(
              value: _ConversationAction.pin,
              child: Row(
                children: <Widget>[
                  Icon(
                    conversation.isPinned
                        ? Icons.push_pin_rounded
                        : Icons.push_pin_outlined,
                    size: 19,
                  ),
                  const SizedBox(width: 10),
                  Text(pinLabel),
                ],
              ),
            ),
            PopupMenuItem<_ConversationAction>(
              value: _ConversationAction.mute,
              child: Row(
                children: <Widget>[
                  Icon(
                    conversation.isMuted
                        ? Icons.notifications_active_outlined
                        : Icons.notifications_off_outlined,
                    size: 19,
                  ),
                  const SizedBox(width: 10),
                  Text(muteLabel),
                ],
              ),
            ),
          ],
        );
        if (selected != null) {
          _performConversationAction(conversation, selected);
        }
        return;
      }
    }

    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => _ConversationActionSheet(
        conversation: conversation,
        pinLabel: pinLabel,
        muteLabel: muteLabel,
        onPin: () {
          Navigator.of(sheetContext).pop();
          _performConversationAction(conversation, _ConversationAction.pin);
        },
        onMute: () {
          Navigator.of(sheetContext).pop();
          _performConversationAction(conversation, _ConversationAction.mute);
        },
      ),
    );
  }

  void _performConversationAction(
    ChatNuConversation conversation,
    _ConversationAction action,
  ) {
    switch (action) {
      case _ConversationAction.pin:
        ref.read(messengerDemoProvider.notifier).togglePin(conversation.id);
      case _ConversationAction.mute:
        ref.read(messengerDemoProvider.notifier).toggleMute(conversation.id);
    }
  }
}

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onClose,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    return Row(
      children: <Widget>[
        Expanded(
          child: TextField(
            key: const Key('conversation-search-field'),
            controller: controller,
            autofocus: true,
            onChanged: onChanged,
            decoration: InputDecoration(
              isDense: true,
              hintText: hintText,
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: palette.glassWeak,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          tooltip: ChatNuStrings.of(context).closeSearch,
          onPressed: onClose,
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }
}

class _RecentPerson extends StatelessWidget {
  const _RecentPerson({required this.conversation, required this.onTap});

  final ChatNuConversation conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: conversation.title,
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        mouseCursor: SystemMouseCursors.click,
        onTap: onTap,
        child: SizedBox(
          width: 58,
          child: Column(
            children: <Widget>[
              _Avatar(
                label: conversation.title,
                imageUrl: conversation.avatarUrl,
                size: 56,
              ),
              const SizedBox(height: 7),
              Text(
                conversation.title.split(' ').first,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationEmptyState extends StatelessWidget {
  const _ConversationEmptyState({
    required this.filtered,
    required this.onStart,
  });

  final bool filtered;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final strings = ChatNuStrings.of(context);
    final palette = context.chatNu;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              filtered ? Icons.search_off_rounded : Icons.chat_bubble_outline,
              size: 34,
              color: palette.textMuted,
            ),
            const SizedBox(height: 14),
            Text(
              filtered ? strings.noSearchResults : strings.noConversations,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (!filtered) ...<Widget>[
              const SizedBox(height: 18),
              FilledButton(
                onPressed: onStart,
                style: FilledButton.styleFrom(
                  backgroundColor: palette.textPrimary,
                  foregroundColor: palette.backgroundElevated,
                ),
                child: Text(strings.startConversation),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.draft,
    required this.selected,
    required this.onTap,
    required this.onContextMenu,
  });

  final ChatNuConversation conversation;
  final String? draft;
  final bool selected;
  final VoidCallback onTap;
  final ValueChanged<Offset?> onContextMenu;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    final strings = ChatNuStrings.of(context);
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(conversation.lastActivityAt),
      alwaysUse24HourFormat: true,
    );
    final trimmedDraft = draft?.trim();
    final preview = trimmedDraft?.isNotEmpty == true
        ? (strings.isPersian
              ? 'پیش‌نویس: $trimmedDraft'
              : 'Draft: $trimmedDraft')
        : conversation.lastMessagePreview;
    final semanticValue = <String>[
      if (preview.trim().isNotEmpty) preview,
      time,
      if (conversation.unreadCount > 0)
        '${conversation.unreadCount} ${strings.unread}',
      if (conversation.isPinned) strings.pinned,
      if (conversation.isMuted) strings.muted,
    ].join(', ');

    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: conversation.title,
      value: semanticValue,
      onTap: onTap,
      onLongPress: () => onContextMenu(null),
      excludeSemantics: true,
      child: GestureDetector(
        excludeFromSemantics: true,
        behavior: HitTestBehavior.opaque,
        onSecondaryTapDown: (details) => onContextMenu(details.globalPosition),
        child: Material(
          color: selected ? palette.glassWeak : Colors.transparent,
          child: InkWell(
            mouseCursor: SystemMouseCursors.click,
            onTap: onTap,
            onLongPress: () => onContextMenu(null),
            hoverColor: palette.textPrimary.withValues(alpha: 0.045),
            focusColor: palette.accentPrimary.withValues(alpha: 0.14),
            highlightColor: palette.textPrimary.withValues(alpha: 0.065),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 10, 18, 10),
              child: Row(
                children: <Widget>[
                  _Avatar(
                    label: conversation.title,
                    imageUrl: conversation.avatarUrl,
                    size: 50,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                conversation.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              time,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: <Widget>[
                            if (conversation.isPinned)
                              Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  end: 5,
                                ),
                                child: Tooltip(
                                  message: strings.pinned,
                                  child: Icon(
                                    Icons.push_pin_outlined,
                                    size: 14,
                                    color: palette.textMuted,
                                  ),
                                ),
                              ),
                            if (conversation.isMuted)
                              Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  end: 5,
                                ),
                                child: Tooltip(
                                  message: strings.muted,
                                  child: Icon(
                                    Icons.notifications_off_outlined,
                                    size: 14,
                                    color: palette.textMuted,
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Text(
                                preview,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: conversation.unreadCount > 0
                                          ? palette.textPrimary
                                          : palette.textSecondary,
                                      fontWeight:
                                          trimmedDraft?.isNotEmpty == true ||
                                              conversation.unreadCount > 0
                                          ? FontWeight.w500
                                          : FontWeight.w400,
                                    ),
                              ),
                            ),
                            if (conversation.unreadCount > 0)
                              Container(
                                constraints: const BoxConstraints(
                                  minWidth: 20,
                                  minHeight: 20,
                                ),
                                margin: const EdgeInsetsDirectional.only(
                                  start: 9,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: palette.accentPrimary,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${conversation.unreadCount}',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.label,
    required this.imageUrl,
    required this.size,
  });

  final String label;
  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    final trimmedUrl = imageUrl?.trim();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: palette.glassMedium,
        image: trimmedUrl == null || trimmedUrl.isEmpty
            ? null
            : DecorationImage(
                image: NetworkImage(trimmedUrl),
                fit: BoxFit.cover,
              ),
      ),
      alignment: Alignment.center,
      child: trimmedUrl == null || trimmedUrl.isEmpty
          ? Text(
              label.isEmpty ? '?' : label.characters.first.toUpperCase(),
              style: Theme.of(context).textTheme.titleMedium,
            )
          : null,
    );
  }
}

class _ConversationActionSheet extends StatelessWidget {
  const _ConversationActionSheet({
    required this.conversation,
    required this.pinLabel,
    required this.muteLabel,
    required this.onPin,
    required this.onMute,
  });

  final ChatNuConversation conversation;
  final String pinLabel;
  final String muteLabel;
  final VoidCallback onPin;
  final VoidCallback onMute;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(18, 10, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: palette.borderHighlight,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            _SheetAction(
              icon: conversation.isPinned
                  ? Icons.push_pin_rounded
                  : Icons.push_pin_outlined,
              label: pinLabel,
              onTap: onPin,
            ),
            Divider(color: palette.borderSubtle, height: 1),
            _SheetAction(
              icon: conversation.isMuted
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_off_outlined,
              label: muteLabel,
              onTap: onMute,
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 6),
      minTileHeight: 58,
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
    );
  }
}
