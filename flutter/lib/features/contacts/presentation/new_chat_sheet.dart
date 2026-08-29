import 'dart:async';

import 'package:chatnu/core/glass/glass_components.dart';
import 'package:chatnu/core/localization/chatnu_strings.dart';
import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:chatnu/core/theme/chatnu_tokens.dart';
import 'package:chatnu/features/accounts/domain/chatnu_user.dart';
import 'package:chatnu/features/home/application/demo_messenger_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showNewChatSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.36),
    builder: (_) => const _NewChatSheet(),
  );
}

enum _CreationMode { direct, groupMembers, groupDetails }

class _NewChatSheet extends ConsumerStatefulWidget {
  const _NewChatSheet();

  @override
  ConsumerState<_NewChatSheet> createState() => _NewChatSheetState();
}

class _NewChatSheetState extends ConsumerState<_NewChatSheet> {
  final _search = TextEditingController();
  final _groupName = TextEditingController();
  final Map<String, ChatNuUser> _selected = <String, ChatNuUser>{};
  Timer? _debounce;
  _CreationMode _mode = _CreationMode.direct;
  bool _submitting = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _groupName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(messengerDemoProvider);
    final strings = ChatNuStrings.of(context);
    final palette = context.chatNu;
    final height = MediaQuery.sizeOf(context).height * 0.82;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 620, maxHeight: height),
          child: GlassSheet(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    if (_mode != _CreationMode.direct)
                      IconButton(
                        tooltip: strings.back,
                        onPressed: _submitting ? null : _goBack,
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                    Expanded(
                      child: Text(
                        switch (_mode) {
                          _CreationMode.direct => strings.newChat,
                          _CreationMode.groupMembers => strings.newGroup,
                          _CreationMode.groupDetails => strings.groupName,
                        },
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    IconButton(
                      tooltip: strings.cancel,
                      onPressed: _submitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: ChatNuSpacing.sm),
                if (_mode == _CreationMode.direct ||
                    _mode == _CreationMode.groupMembers) ...<Widget>[
                  if (_mode == _CreationMode.direct)
                    Padding(
                      padding: const EdgeInsets.only(bottom: ChatNuSpacing.sm),
                      child: GlassButton(
                        label: strings.newGroup,
                        icon: Icons.group_add_outlined,
                        onPressed: _submitting
                            ? null
                            : () {
                                setState(() {
                                  _mode = _CreationMode.groupMembers;
                                  _selected.clear();
                                });
                              },
                      ),
                    ),
                  if (_selected.isNotEmpty) ...<Widget>[
                    Text(
                      strings.selectedMembers,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: ChatNuSpacing.xs),
                    SizedBox(
                      height: 42,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: _selected.values
                            .map(
                              (user) => Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  end: ChatNuSpacing.xs,
                                ),
                                child: InputChip(
                                  avatar: CircleAvatar(
                                    child: Text(user.initials),
                                  ),
                                  label: Text(user.displayName),
                                  onDeleted: _submitting
                                      ? null
                                      : () => _toggleUser(user),
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
                    const SizedBox(height: ChatNuSpacing.sm),
                  ],
                  GlassSearchField(
                    controller: _search,
                    hintText: strings.searchByUsername,
                    autofocus: true,
                    onChanged: _searchChanged,
                  ),
                  const SizedBox(height: ChatNuSpacing.sm),
                  if (state.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: ChatNuSpacing.xs),
                      child: Text(
                        state.error!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: palette.destructive,
                        ),
                      ),
                    ),
                  Flexible(
                    child: _UserResults(
                      users: state.contactResults,
                      query: _search.text,
                      selected: _selected,
                      groupMode: _mode == _CreationMode.groupMembers,
                      onTap: _mode == _CreationMode.groupMembers
                          ? _toggleUser
                          : _openDirect,
                    ),
                  ),
                  if (_mode == _CreationMode.groupMembers) ...<Widget>[
                    const SizedBox(height: ChatNuSpacing.sm),
                    GlassButton(
                      label: strings.done,
                      icon: Icons.arrow_forward_rounded,
                      prominent: true,
                      onPressed: _selected.isEmpty || _submitting
                          ? null
                          : () {
                              FocusScope.of(context).unfocus();
                              setState(
                                () => _mode = _CreationMode.groupDetails,
                              );
                            },
                    ),
                  ],
                ] else ...<Widget>[
                  GlassTextField(
                    controller: _groupName,
                    labelText: strings.groupName,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => unawaited(_createGroup()),
                  ),
                  const SizedBox(height: ChatNuSpacing.md),
                  Wrap(
                    spacing: ChatNuSpacing.xs,
                    runSpacing: ChatNuSpacing.xs,
                    children: _selected.values
                        .map(
                          (user) => Chip(
                            avatar: CircleAvatar(child: Text(user.initials)),
                            label: Text(user.displayName),
                          ),
                        )
                        .toList(growable: false),
                  ),
                  const SizedBox(height: ChatNuSpacing.lg),
                  GlassButton(
                    label: strings.create,
                    icon: Icons.group_add_rounded,
                    prominent: true,
                    onPressed:
                        _groupName.text.trim().isEmpty || _submitting
                        ? null
                        : () => unawaited(_createGroup()),
                  ),
                  if (_submitting) ...<Widget>[
                    const SizedBox(height: ChatNuSpacing.sm),
                    const LinearProgressIndicator(minHeight: 2),
                  ],
                ],
              ],
            ),
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

  void _toggleUser(ChatNuUser user) {
    setState(() {
      if (_selected.containsKey(user.username)) {
        _selected.remove(user.username);
      } else {
        _selected[user.username] = user;
      }
    });
  }

  Future<void> _openDirect(ChatNuUser user) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final conversation = await ref
        .read(messengerDemoProvider.notifier)
        .openDirect(user.username);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (conversation != null) Navigator.of(context).pop();
  }

  Future<void> _createGroup() async {
    final title = _groupName.text.trim();
    if (title.isEmpty || _selected.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    final conversation = await ref
        .read(messengerDemoProvider.notifier)
        .createGroup(
          title: title,
          usernames: _selected.values
              .map((user) => user.username)
              .toList(growable: false),
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (conversation != null) Navigator.of(context).pop();
  }

  void _goBack() {
    setState(() {
      if (_mode == _CreationMode.groupDetails) {
        _mode = _CreationMode.groupMembers;
      } else {
        _mode = _CreationMode.direct;
        _selected.clear();
      }
    });
  }
}

class _UserResults extends StatelessWidget {
  const _UserResults({
    required this.users,
    required this.query,
    required this.selected,
    required this.groupMode,
    required this.onTap,
  });

  final List<ChatNuUser> users;
  final String query;
  final Map<String, ChatNuUser> selected;
  final bool groupMode;
  final ValueChanged<ChatNuUser> onTap;

  @override
  Widget build(BuildContext context) {
    final strings = ChatNuStrings.of(context);
    if (users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(ChatNuSpacing.lg),
          child: Text(
            query.trim().length < 2
                ? strings.typeTwoCharacters
                : strings.noUsersFound,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final isSelected = selected.containsKey(user.username);
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: ChatNuSpacing.xs,
          ),
          onTap: () => onTap(user),
          leading: GlassAvatar(
            label: user.displayName,
            imageUrl: user.avatarUrl,
          ),
          title: Text(user.displayName),
          subtitle: Text('@${user.username}'),
          trailing: groupMode
              ? Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                )
              : const Icon(Icons.chat_bubble_outline_rounded),
        );
      },
    );
  }
}
