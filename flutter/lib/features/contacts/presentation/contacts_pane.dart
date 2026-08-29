import 'dart:async';

import 'package:chatnu/core/glass/glass_surface.dart';
import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:chatnu/core/theme/chatnu_tokens.dart';
import 'package:chatnu/features/accounts/domain/chatnu_user.dart';
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
    final palette = context.chatNu;
    return ColoredBox(
      color: palette.backgroundPrimary,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.all(ChatNuSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Contacts',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _showCreateGroup,
                        icon: const Icon(Icons.group_add_outlined),
                        label: const Text('New group'),
                      ),
                    ],
                  ),
                  const SizedBox(height: ChatNuSpacing.md),
                  TextField(
                    key: const Key('contact-search-field'),
                    controller: _search,
                    autocorrect: false,
                    textCapitalization: TextCapitalization.none,
                    onChanged: _searchChanged,
                    decoration: const InputDecoration(
                      labelText: 'Find people',
                      hintText: 'Search by username',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                  const SizedBox(height: ChatNuSpacing.md),
                  if (state.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: ChatNuSpacing.sm),
                      child: Text(
                        state.error!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: palette.destructive,
                        ),
                      ),
                    ),
                  Expanded(
                    child: state.contactResults.isEmpty
                        ? Center(
                            child: Text(
                              _search.text.trim().length < 2
                                  ? 'Type at least two characters to search the selected ChatNU server.'
                                  : 'No users found.',
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.separated(
                            itemCount: state.contactResults.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 6),
                            itemBuilder: (context, index) {
                              final user = state.contactResults[index];
                              return _ContactTile(
                                user: user,
                                onTap: () => _openDirect(user),
                              );
                            },
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

  void _searchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      unawaited(ref.read(messengerDemoProvider.notifier).searchUsers(value));
    });
    setState(() {});
  }

  Future<void> _openDirect(ChatNuUser user) async {
    await ref.read(messengerDemoProvider.notifier).openDirect(user.username);
  }

  Future<void> _showCreateGroup() async {
    final title = TextEditingController();
    final usernames = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New group'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: title,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Group name'),
              ),
              const SizedBox(height: ChatNuSpacing.sm),
              TextField(
                controller: usernames,
                decoration: const InputDecoration(
                  labelText: 'Usernames',
                  hintText: 'leila, navid',
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (result == true && mounted) {
      await ref
          .read(messengerDemoProvider.notifier)
          .createGroup(
            title: title.text,
            usernames: usernames.text
                .split(',')
                .map((value) => value.trim())
                .where((value) => value.isNotEmpty)
                .toList(growable: false),
          );
    }
    title.dispose();
    usernames.dispose();
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.user, required this.onTap});

  final ChatNuUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    return GlassSurface(
      variant: GlassVariant.weak,
      borderRadius: ChatNuRadii.md,
      padding: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: palette.glassStrong,
          child: Text(user.initials),
        ),
        title: Text(user.displayName),
        subtitle: Text('@${user.username}'),
        trailing: const Icon(Icons.chat_bubble_outline_rounded),
      ),
    );
  }
}
