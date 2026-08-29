import 'package:chatnu/core/glass/glass_surface.dart';
import 'package:chatnu/core/localization/chatnu_strings.dart';
import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:chatnu/core/theme/chatnu_tokens.dart';
import 'package:chatnu/features/conversations/domain/conversation.dart';
import 'package:chatnu/features/home/application/demo_messenger_controller.dart';
import 'package:chatnu/shared/widgets/chatnu_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ConversationFilter { all, unread, personal, groups }

class ConversationListPane extends ConsumerStatefulWidget {
  const ConversationListPane({
    required this.onSelected,
    super.key,
  });

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
    final conversations = state.conversations.where((conversation) {
      final matchesFilter = switch (_filter) {
        ConversationFilter.all => true,
        ConversationFilter.unread => conversation.unreadCount > 0,
        ConversationFilter.personal =>
          conversation.kind == ConversationKind.direct,
        ConversationFilter.groups => conversation.kind == ConversationKind.group,
      };
      final matchesQuery = query.isEmpty ||
          conversation.title.toLowerCase().contains(query) ||
          conversation.lastMessagePreview.toLowerCase().contains(query);
      return matchesFilter && matchesQuery;
    }).toList(growable: false);

    return ColoredBox(
      color: palette.backgroundSecondary,
      child: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ChatNuSpacing.md,
                ChatNuSpacing.md,
                ChatNuSpacing.md,
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
                  GlassIconButton(
                    icon: Icons.edit_square,
                    tooltip: strings.newConversation,
                    onPressed: () => _showLocalOnly(context, strings.mockMode),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ChatNuSpacing.md,
              ),
              child: TextField(
                key: const Key('conversation-search-field'),
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: strings.searchConversations,
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: palette.glassWeak,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ChatNuRadii.md),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: ChatNuSpacing.sm),
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: ChatNuSpacing.md,
                ),
                children: <Widget>[
                  _FilterChip(
                    label: strings.all,
                    selected: _filter == ConversationFilter.all,
                    onTap: () => _selectFilter(ConversationFilter.all),
                  ),
                  _FilterChip(
                    label: strings.unread,
                    selected: _filter == ConversationFilter.unread,
                    onTap: () => _selectFilter(ConversationFilter.unread),
                  ),
                  _FilterChip(
                    label: strings.personal,
                    selected: _filter == ConversationFilter.personal,
                    onTap: () => _selectFilter(ConversationFilter.personal),
                  ),
                  _FilterChip(
                    label: strings.groups,
                    selected: _filter == ConversationFilter.groups,
                    onTap: () => _selectFilter(ConversationFilter.groups),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ChatNuSpacing.xs),
            Expanded(
              child: ListView.builder(
                key: const Key('conversation-list'),
                itemCount: conversations.length,
                itemBuilder: (context, index) {
                  final conversation = conversations[index];
                  return _ConversationTile(
                    conversation: conversation,
                    selected:
                        conversation.id == state.selectedConversationId,
                    onTap: () => widget.onSelected(conversation.id),
                    onLongPress: () {
                      ref
                          .read(messengerDemoProvider.notifier)
                          .togglePin(conversation.id);
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(ChatNuSpacing.sm),
              child: Text(
                strings.mockMode,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectFilter(ConversationFilter value) {
    setState(() => _filter = value);
  }

  void _showLocalOnly(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: ChatNuSpacing.xs),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        side: BorderSide(
          color: selected ? palette.borderHighlight : palette.borderSubtle,
        ),
        selectedColor: palette.glassStrong,
        backgroundColor: palette.glassWeak,
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  final ChatNuConversation conversation;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

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
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: AnimatedContainer(
          duration: ChatNuMotion.micro,
          margin: const EdgeInsets.symmetric(
            horizontal: ChatNuSpacing.xs,
            vertical: 2,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: ChatNuSpacing.sm,
            vertical: ChatNuSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ChatNuRadii.md),
            color: selected ? palette.glassMedium : Colors.transparent,
          ),
          child: Row(
            children: <Widget>[
              _Avatar(
                title: conversation.title,
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
                        Text(time, style: Theme.of(context).textTheme.bodySmall),
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
                            padding: const EdgeInsetsDirectional.only(start: 5),
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
                          Container(
                            margin: const EdgeInsetsDirectional.only(start: 7),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: palette.accentPrimary,
                              borderRadius: BorderRadius.circular(
                                ChatNuRadii.pill,
                              ),
                            ),
                            child: Text(
                              '${conversation.unreadCount}',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
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
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.title, required this.group});

  final String title;
  final bool group;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    return CircleAvatar(
      radius: 25,
      backgroundColor: palette.glassStrong,
      foregroundColor: palette.textPrimary,
      child: group
          ? const Icon(Icons.group_outlined)
          : Text(
              title.isEmpty ? '?' : title.substring(0, 1).toUpperCase(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
    );
  }
}
