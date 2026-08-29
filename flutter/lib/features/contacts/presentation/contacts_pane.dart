import 'dart:async';

import 'package:chatnu/core/glass/glass_components.dart';
import 'package:chatnu/core/localization/chatnu_strings.dart';
import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:chatnu/core/theme/chatnu_tokens.dart';
import 'package:chatnu/features/accounts/domain/chatnu_user.dart';
import 'package:chatnu/features/contacts/presentation/new_chat_sheet.dart';
import 'package:chatnu/features/home/application/demo_messenger_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ContactsPane extends ConsumerStatefulWidget {
  const ContactsPane({super.key});

  @override
  ConsumerState<ContactsPane> createState() => _ContactsPaneState();
}

class _ContactsPaneState extends ConsumerState<ContactsPane> {
  final _search = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(messengerDemoProvider);
    final strings = ChatNuStrings.of(context);
    final palette = context.chatNu;
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: ChatNuSizing.contentMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              GlassAppBar(
                title: Text(
                  strings.contacts,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                subtitle: Text(
                  strings.secureMessaging,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                actions: <Widget>[
                  GlassButton(
                    label: strings.newGroup,
                    icon: Icons.group_add_outlined,
                    onPressed: () => unawaited(showNewChatSheet(context)),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  ChatNuSpacing.lg,
                  ChatNuSpacing.sm,
                  ChatNuSpacing.lg,
                  ChatNuSpacing.sm,
                ),
                child: GlassSearchField(
                  key: const Key('contact-search-field'),
                  controller: _search,
                  hintText: strings.searchByUsername,
                  onChanged: _searchChanged,
                ),
              ),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ChatNuSpacing.lg,
                  ),
                  child: Text(
                    state.error!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: palette.destructive,
                    ),
                  ),
                ),
              Expanded(
                child: state.contactResults.isEmpty
                    ? _ContactsEmptyState(query: _search.text)
                    : ListView.builder(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          ChatNuSpacing.md,
                          ChatNuSpacing.xs,
                          ChatNuSpacing.md,
                          ChatNuSpacing.xl,
                        ),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        itemCount: state.contactResults.length,
                        itemBuilder: (context, index) {
                          final user = state.contactResults[index];
                          return RepaintBoundary(
                            child: _ContactTile(
                              user: user,
                              onTap: () => unawaited(_openDirect(user)),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _searchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 260), () {
      if (!mounted) return;
      unawaited(ref.read(messengerDemoProvider.notifier).searchUsers(value));
    });
    setState(() {});
  }

  Future<void> _openDirect(ChatNuUser user) async {
    await ref.read(messengerDemoProvider.notifier).openDirect(user.username);
  }
}

class _ContactsEmptyState extends StatelessWidget {
  const _ContactsEmptyState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final strings = ChatNuStrings.of(context);
    final palette = context.chatNu;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ChatNuSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.glassMedium,
                border: Border.all(color: palette.borderHighlight),
              ),
              alignment: Alignment.center,
              child: Icon(
                query.trim().length < 2
                    ? Icons.person_search_outlined
                    : Icons.search_off_rounded,
                color: palette.accentPrimary,
              ),
            ),
            const SizedBox(height: ChatNuSpacing.md),
            Text(
              query.trim().length < 2
                  ? strings.typeTwoCharacters
                  : strings.noUsersFound,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.user, required this.onTap});

  final ChatNuUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    return Semantics(
      button: true,
      label: '${user.displayName}, @${user.username}',
      child: InkWell(
        borderRadius: BorderRadius.circular(ChatNuRadii.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ChatNuSpacing.sm,
            vertical: ChatNuSpacing.sm,
          ),
          child: Row(
            children: <Widget>[
              GlassAvatar(
                label: user.displayName,
                imageUrl: user.avatarUrl,
              ),
              const SizedBox(width: ChatNuSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      user.displayName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '@${user.username}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chat_bubble_outline_rounded,
                color: palette.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
