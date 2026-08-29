import 'dart:async';

import 'package:chatnu/core/glass/glass_components.dart';
import 'package:chatnu/core/localization/chatnu_strings.dart';
import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:chatnu/core/theme/chatnu_tokens.dart';
import 'package:chatnu/features/contacts/presentation/new_chat_sheet.dart';
import 'package:chatnu/features/conversations/domain/conversation.dart';
import 'package:chatnu/features/home/application/demo_messenger_controller.dart';
import 'package:chatnu/shared/widgets/chatnu_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ConversationFilter { all, unread, personal, groups }

class ConversationListPane extends ConsumerStatefulWidget {
  const ConversationListPane({required this.onSelected, super.key});

  final ValueChanged<String> onSelected;

  @override
  ConsumerState<ConversationListPane> createState() =>
      _ConversationListPaneState();
}

class _ConversationListPaneState extends ConsumerState<ConversationListPane> {
  final _searchController = TextEditingController();
  ConversationFilter _filter = ConversationFilter.all;

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
          final matchesFilter = switch (_filter) {
            ConversationFilter.all => true,
            ConversationFilter.unread => conversation.unreadCount > 0,
            ConversationFilter.personal =>
              conversation.kind == ConversationKind.direct,
            ConversationFilter.groups =>
              conversation.kind == ConversationKind.group,
          };
          final matchesQuery =
              query.isEmpty ||
              conversation.title.toLowerCase().contains(query) ||
              conversation.lastMessagePreview.toLowerCase().contains(query);
          return matchesFilter && matchesQuery;
        })
        .toList(growable: false);

    return ColoredBox(
      color: palette.backgroundSecondary.withValues(alpha: 0.88),
      child: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                ChatNuSpacing.md,
                ChatNuSpacing.md,
                ChatNuSpacing.sm,
                ChatNuSpacing.sm,
              ),
              child: Row(
                children: <Widget>[
                  const ChatNuMark(size: 36),
                  const SizedBox(width: ChatNuSpacing.sm),
                  Expanded(
                    child: Text(
                      strings.appName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  GlassButton(
                    label: strings.newChat,
                    icon: Icons.edit_square,
                    onPressed: () => unawaited(showNewChatSheet(context)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: ChatNuSpacing.md),
              child: GlassSearchField(
                key: const Key('conversation-search-field'),
                controller: _searchController,
                hintText: strings.searchConversations,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: ChatNuSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: ChatNuSpacing.md),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: GlassSegmentedControl<ConversationFilter>(
                  value: _filter,
                  onChanged: (value) => setState(() => _filter = value),
                  items: <ConversationFilter, String>{
                    ConversationFilter.all: strings.all,
                    ConversationFilter.unread: strings.unread,
                    ConversationFilter.personal: strings.personal,
                    ConversationFilter.groups: strings.groups,
                  },
                ),
              ),
            ),
            const SizedBox(height: ChatNuSpacing.xs),
            Expanded(
              child: RefreshIndicator(
                onRefresh: ref
                    .read(messengerDemoProvider.notifier)
                    .refreshConversations,
                child: conversations.isEmpty
                    ? _ConversationEmptyState(
                        hasAnyConversation: state.conversations.isNotEmpty,
                        queryActive: query.isNotEmpty,
                        onStart: () => unawaited(showNewChatSheet(context)),
                      )
                    : ListView.builder(
                        key: const Key('conversation-list'),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          ChatNuSpacing.xs,
                          2,
                          ChatNuSpacing.xs,
                          ChatNuSpacing.md,
                        ),
                        itemCount: conversations.length,
                        itemBuilder: (context, index) {
                          final conversation = conversations[index];
                          return RepaintBoundary(
                            child: _ConversationTile(
                              conversation: conversation,
                              selected:
                                  conversation.id ==
                                  state.selectedConversationId,
                              onTap: () => widget.onSelected(conversation.id),
                              onContextMenu: () =>
                                  _showConversationMenu(context, conversation),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
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
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => GlassSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: Icon(
                conversation.isPinned
                    ? Icons.push_pin_rounded
                    : Icons.push_pin_outlined,
              ),
              title: Text(conversation.isPinned ? strings.unpin : strings.pin),
              onTap: () {
                Navigator.of(sheetContext).pop();
                ref
                    .read(messengerDemoProvider.notifier)
                    .togglePin(conversation.id);
              },
            ),
            ListTile(
              leading: Icon(
                conversation.isMuted
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_off_outlined,
              ),
              title: Text(conversation.isMuted ? strings.unmute : strings.mute),
              onTap: () {
                Navigator.of(sheetContext).pop();
                ref
                    .read(messengerDemoProvider.notifier)
                    .toggleMute(conversation.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationEmptyState extends StatelessWidget {
  const _ConversationEmptyState({
    required this.hasAnyConversation,
    required this.queryActive,
    required this.onStart,
  });

  final bool hasAnyConversation;
  final bool queryActive;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final strings = ChatNuStrings.of(context);
    final palette = context.chatNu;
    final filtered = queryActive || hasAnyConversation;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: <Widget>[
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.16),
        Padding(
          padding: const EdgeInsets.all(ChatNuSpacing.lg),
          child: Column(
            children: <Widget>[
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.glassMedium,
                  border: Border.all(color: palette.borderHighlight),
                ),
                alignment: Alignment.center,
                child: Icon(
                  filtered ? Icons.search_off_rounded : Icons.chat_outlined,
                  color: palette.accentPrimary,
                ),
              ),
              const SizedBox(height: ChatNuSpacing.md),
              Text(
                filtered ? strings.noSearchResults : strings.noConversations,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (!filtered) ...<Widget>[
                const SizedBox(height: ChatNuSpacing.md),
                GlassButton(
                  label: strings.startConversation,
                  icon: Icons.edit_square,
                  prominent: true,
                  onPressed: onStart,
                ),
              ],
            ],
          ),
        ),
      ],
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
          borderRadius: BorderRadius.circular(ChatNuRadii.md),
          onTap: onTap,
          onLongPress: onContextMenu,
          child: AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : ChatNuMotion.micro,
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.symmetric(
              horizontal: ChatNuSpacing.sm,
              vertical: ChatNuSpacing.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(ChatNuRadii.md),
              color: selected ? palette.glassMedium : Colors.transparent,
              border: Border.all(
                color: selected ? palette.borderSubtle : Colors.transparent,
              ),
            ),
            child: Row(
              children: <Widget>[
                GlassAvatar(
                  label: conversation.title,
                  imageUrl: conversation.avatarUrl,
                  group: conversation.kind == ConversationKind.group,
                ),
                const SizedBox(width: ChatNuSpacing.sm),
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
                          const SizedBox(width: ChatNuSpacing.xs),
                          Text(
                            time,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              conversation.lastMessagePreview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          if (conversation.isMuted)
                            Tooltip(
                              message: strings.muted,
                              child: Icon(
                                Icons.notifications_off_outlined,
                                size: 16,
                                color: palette.textMuted,
                              ),
                            ),
                          if (conversation.isPinned)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(
                                start: 5,
                              ),
                              child: Tooltip(
                                message: strings.pinned,
                                child: Icon(
                                  Icons.push_pin_outlined,
                                  size: 16,
                                  color: palette.textMuted,
                                ),
                              ),
                            ),
                          if (conversation.unreadCount > 0)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(
                                start: 7,
                              ),
                              child: GlassBadge(
                                label: '${conversation.unreadCount}',
                                semanticLabel:
                                    '${conversation.unreadCount} ${strings.unread}',
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
