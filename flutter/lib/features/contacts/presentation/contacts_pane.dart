import 'dart:async';

import 'package:chatnu/core/glass/glass_components.dart';
import 'package:chatnu/core/localization/chatnu_strings.dart';
import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:chatnu/core/theme/chatnu_tokens.dart';
import 'package:chatnu/features/accounts/domain/chatnu_user.dart';
import 'package:chatnu/features/contacts/application/contact_book_controller.dart';
import 'package:chatnu/features/contacts/presentation/new_chat_sheet.dart';
import 'package:chatnu/features/home/application/demo_messenger_controller.dart';
import 'package:enefty_icons/enefty_icons.dart';
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
    final contactBook = ref.watch(contactBookProvider);
    final strings = ChatNuStrings.of(context);
    final palette = context.chatNu;
    final searching = _search.text.trim().length >= 2;
    final visible = searching ? state.contactResults : contactBook.contacts;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: ChatNuSizing.contentMaxWidth,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              GlassAppBar(
                title: Text(
                  strings.contacts,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                subtitle: Text(
                  strings.isPersian
                      ? 'مخاطبان ذخیره‌شده روی این حساب و جستجوی امن سرور'
                      : 'Saved on this account + secure server directory',
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
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ChatNuSpacing.lg,
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      EneftyIcons.people_outline,
                      size: 18,
                      color: palette.textMuted,
                    ),
                    const SizedBox(width: ChatNuSpacing.xs),
                    Expanded(
                      child: Text(
                        searching
                            ? (strings.isPersian
                                  ? 'نتایج دایرکتوری سرور'
                                  : 'Server directory results')
                            : (strings.isPersian
                                  ? 'مخاطبان ذخیره‌شده روی این دستگاه'
                                  : 'Saved contacts on this device'),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                  ],
                ),
              ),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ChatNuSpacing.lg,
                    vertical: ChatNuSpacing.xs,
                  ),
                  child: Text(
                    state.error!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: palette.destructive,
                    ),
                  ),
                ),
              Expanded(
                child: contactBook.loading && !searching
                    ? const Center(child: CircularProgressIndicator())
                    : visible.isEmpty
                    ? _ContactsEmptyState(query: _search.text, saved: !searching)
                    : ListView.builder(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          ChatNuSpacing.md,
                          ChatNuSpacing.xs,
                          ChatNuSpacing.md,
                          ChatNuSpacing.xl,
                        ),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        itemCount: visible.length,
                        itemBuilder: (context, index) {
                          final user = visible[index];
                          final saved = contactBook.contains(user.id);
                          return RepaintBoundary(
                            child: _ContactTile(
                              user: user,
                              saved: saved,
                              onTap: () => unawaited(_openDirect(user)),
                              onToggleSaved: () => saved
                                  ? unawaited(
                                      ref
                                          .read(contactBookProvider.notifier)
                                          .remove(user.id),
                                    )
                                  : unawaited(
                                      ref
                                          .read(contactBookProvider.notifier)
                                          .add(user),
                                    ),
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
  const _ContactsEmptyState({required this.query, required this.saved});

  final String query;
  final bool saved;

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
                saved ? EneftyIcons.people_outline : Icons.search_off_rounded,
                color: palette.accentPrimary,
              ),
            ),
            const SizedBox(height: ChatNuSpacing.md),
            Text(
              saved
                  ? (strings.isPersian
                        ? 'هنوز مخاطبی ذخیره نشده. حداقل دو حرف جستجو کنید و یک کاربر را ذخیره کنید.'
                        : 'No saved contacts yet. Search at least two characters and save a user.')
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
  const _ContactTile({
    required this.user,
    required this.saved,
    required this.onTap,
    required this.onToggleSaved,
  });

  final ChatNuUser user;
  final bool saved;
  final VoidCallback onTap;
  final VoidCallback onToggleSaved;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    final strings = ChatNuStrings.of(context);
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
              GlassAvatar(label: user.displayName, imageUrl: user.avatarUrl),
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
              IconButton(
                tooltip: saved
                    ? (strings.isPersian ? 'حذف از مخاطبان' : 'Remove contact')
                    : (strings.isPersian ? 'ذخیره مخاطب' : 'Save contact'),
                onPressed: onToggleSaved,
                icon: Icon(
                  saved ? Icons.person_remove_outlined : Icons.person_add_outlined,
                  color: saved ? palette.accentPrimary : palette.textMuted,
                ),
              ),
              Icon(Icons.chat_bubble_outline_rounded, color: palette.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
