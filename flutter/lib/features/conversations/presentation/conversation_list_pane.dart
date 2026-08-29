import 'dart:async';

import 'package:chatnu/core/localization/chatnu_strings.dart';
import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:chatnu/core/theme/chatnu_tokens.dart';
import 'package:chatnu/features/contacts/presentation/new_chat_sheet.dart';
import 'package:chatnu/features/conversations/domain/conversation.dart';
import 'package:chatnu/features/home/application/demo_messenger_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConversationListPane extends ConsumerStatefulWidget {
  const ConversationListPane({required this.onSelected, super.key});

  final ValueChanged<String> onSelected;

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
    final palette = context.chatNu;
    final state = ref.watch(messengerDemoProvider);
    final query = _searchController.text.trim().toLowerCase();
    final conversations = state.conversations
        .where((conversation) {
          return query.isEmpty ||
              conversation.title.toLowerCase().contains(query) ||
              conversation.lastMessagePreview.toLowerCase().contains(query);
        })
        .toList(growable: false);
    final recent = state.conversations
        .where((item) => item.kind == ConversationKind.direct)
        .take(6)
        .toList(growable: false);

    return ColoredBox(
      color: palette.backgroundSecondary,
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
                      itemCount: recent.length + 1,
                      separatorBuilder: (_, _) => const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _RecentAction(
                            label: strings.newChat,
                            onTap: () => unawaited(showNewChatSheet(context)),
                          );
                        }
                        final conversation = recent[index - 1];
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
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          strings.chats,
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(fontSize: 21),
                        ),
                      ),
                      IconButton(
                        tooltip: strings.newChat,
                        onPressed: () => unawaited(showNewChatSheet(context)),
                        icon: const Icon(Icons.more_horiz_rounded, size: 26),
                      ),
                    ],
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
                        selected:
                            conversation.id == state.selectedConversationId,
                        onTap: () => widget.onSelected(conversation.id),
                        onContextMenu: () =>
                            _showConversationMenu(context, conversation),
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
    ChatNuConversation conversation,
  ) async {
    final strings = ChatNuStrings.of(context);
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => _ConversationActionSheet(
        conversation: conversation,
        pinLabel: conversation.isPinned ? strings.unpin : strings.pin,
        muteLabel: conversation.isMuted ? strings.unmute : strings.mute,
        onPin: () {
          Navigator.of(sheetContext).pop();
          ref.read(messengerDemoProvider.notifier).togglePin(conversation.id);
        },
        onMute: () {
          Navigator.of(sheetContext).pop();
          ref.read(messengerDemoProvider.notifier).toggleMute(conversation.id);
        },
      ),
    );
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
        IconButton(onPressed: onClose, icon: const Icon(Icons.close_rounded)),
      ],
    );
  }
}

class _RecentAction extends StatelessWidget {
  const _RecentAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: onTap,
      child: SizedBox(
        width: 58,
        child: Column(
          children: <Widget>[
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.backgroundElevated,
                border: Border.all(
                  color: palette.borderSubtle,
                  style: BorderStyle.solid,
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.add_rounded, size: 28),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentPerson extends StatelessWidget {
  const _RecentPerson({required this.conversation, required this.onTap});

  final ChatNuConversation conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
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
    required this.selected,
    required this.onTap,
    required this.onContextMenu,
  });

  final ChatNuConversation conversation;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onContextMenu;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    final strings = ChatNuStrings.of(context);
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(conversation.lastActivityAt),
      alwaysUse24HourFormat: true,
    );
    return Semantics(
      button: true,
      selected: selected,
      label: conversation.title,
      child: GestureDetector(
        onSecondaryTapDown: (_) => onContextMenu(),
        child: InkWell(
          onTap: onTap,
          onLongPress: onContextMenu,
          child: AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : ChatNuMotion.micro,
            color: selected ? palette.glassWeak : Colors.transparent,
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
                              padding: const EdgeInsetsDirectional.only(end: 5),
                              child: Icon(
                                Icons.push_pin_outlined,
                                size: 14,
                                color: palette.textMuted,
                              ),
                            ),
                          if (conversation.isMuted)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(end: 5),
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
                              conversation.lastMessagePreview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: conversation.unreadCount > 0
                                        ? palette.textPrimary
                                        : palette.textSecondary,
                                    fontWeight: conversation.unreadCount > 0
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
