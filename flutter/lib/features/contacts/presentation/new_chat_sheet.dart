import 'dart:async';

import 'package:chatnu/core/localization/chatnu_strings.dart';
import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:chatnu/features/accounts/domain/chatnu_user.dart';
import 'package:chatnu/features/home/application/demo_messenger_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showNewChatSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    barrierColor: Colors.black.withValues(alpha: 0.38),
    builder: (_) => const _NewChatSheet(),
  );
}

enum _CreationMode { menu, direct, groupMembers, groupDetails }

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
  _CreationMode _mode = _CreationMode.menu;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _groupName.addListener(_refresh);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _groupName
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    return AnimatedSize(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: _mode == _CreationMode.menu
          ? _buildMenu()
          : Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.78,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: palette.backgroundElevated),
                  child: _buildCreationFlow(),
                ),
              ),
            ),
    );
  }

  Widget _buildMenu() {
    final strings = ChatNuStrings.of(context);
    final palette = context.chatNu;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 9, 14, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: palette.borderHighlight,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            _MenuAction(
              icon: Icons.chat_bubble_outline_rounded,
              title: strings.newChat,
              subtitle: strings.isPersian
                  ? 'به یک کاربر ChatNU پیام بدهید'
                  : 'Send a message to a ChatNU user',
              onTap: () => setState(() => _mode = _CreationMode.direct),
            ),
            Divider(color: palette.borderSubtle, height: 1),
            _MenuAction(
              icon: Icons.person_search_outlined,
              title: strings.isPersian ? 'پیدا کردن افراد' : 'Find people',
              subtitle: strings.isPersian
                  ? 'افراد را با نام کاربری پیدا کنید'
                  : 'Search the directory by username',
              onTap: () {
                ref
                    .read(messengerDemoProvider.notifier)
                    .setDestination(MessengerDestination.contacts);
                Navigator.of(context).pop();
              },
            ),
            Divider(color: palette.borderSubtle, height: 1),
            _MenuAction(
              icon: Icons.group_outlined,
              title: strings.newGroup,
              subtitle: strings.isPersian
                  ? 'یک گفتگوی گروهی امن بسازید'
                  : 'Create a secure group conversation',
              onTap: () => setState(() {
                _mode = _CreationMode.groupMembers;
                _selected.clear();
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreationFlow() {
    final state = ref.watch(messengerDemoProvider);
    final strings = ChatNuStrings.of(context);
    final palette = context.chatNu;
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(8, 10, 8, 8),
          child: Row(
            children: <Widget>[
              IconButton(
                tooltip: strings.back,
                onPressed: _submitting ? null : _goBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
              ),
              Expanded(
                child: Text(
                  switch (_mode) {
                    _CreationMode.direct => strings.newChat,
                    _CreationMode.groupMembers => strings.newGroup,
                    _CreationMode.groupDetails => strings.groupName,
                    _CreationMode.menu => '',
                  },
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
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
        ),
        Divider(color: palette.borderSubtle, height: 1),
        if (_mode == _CreationMode.groupDetails)
          Expanded(child: _buildGroupDetails())
        else ...<Widget>[
          if (_selected.isNotEmpty)
            SizedBox(
              height: 76,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                itemCount: _selected.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final user = _selected.values.elementAt(index);
                  return _SelectedPerson(
                    user: user,
                    onRemove: _submitting ? null : () => _toggleUser(user),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(18, 14, 18, 10),
            child: TextField(
              key: const Key('new-chat-search-field'),
              controller: _search,
              autofocus: true,
              autocorrect: false,
              textCapitalization: TextCapitalization.none,
              onChanged: _searchChanged,
              decoration: InputDecoration(
                hintText: strings.searchByUsername,
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
          if (state.error != null)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(18, 0, 18, 8),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  state.error!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: palette.destructive,
                  ),
                ),
              ),
            ),
          Expanded(
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
          if (_mode == _CreationMode.groupMembers)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(18, 10, 18, 14),
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: palette.textPrimary,
                    foregroundColor: palette.backgroundElevated,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: _selected.isEmpty || _submitting
                      ? null
                      : () {
                          FocusScope.of(context).unfocus();
                          setState(() => _mode = _CreationMode.groupDetails);
                        },
                  child: Text(strings.done),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildGroupDetails() {
    final strings = ChatNuStrings.of(context);
    final palette = context.chatNu;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SizedBox(height: 12),
          Text(
            strings.isPersian ? 'گروهتان را نام‌گذاری کنید' : 'Name your group',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            strings.isPersian
                ? 'این نام برای همه اعضای گفتگو نمایش داده می‌شود.'
                : 'This name is visible to everyone in the conversation.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 28),
          TextField(
            key: const Key('new-group-name-field'),
            controller: _groupName,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => unawaited(_createGroup()),
            decoration: InputDecoration(labelText: strings.groupName),
          ),
          const SizedBox(height: 24),
          Text(
            strings.selectedMembers,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _selected.values
                .map(
                  (user) => Chip(
                    avatar: CircleAvatar(child: Text(user.initials)),
                    label: Text(user.displayName),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 28),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              backgroundColor: palette.textPrimary,
              foregroundColor: palette.backgroundElevated,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            onPressed: _groupName.text.trim().isEmpty || _submitting
                ? null
                : () => unawaited(_createGroup()),
            child: _submitting
                ? SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: palette.backgroundElevated,
                    ),
                  )
                : Text(strings.create),
          ),
        ],
      ),
    );
  }

  void _refresh() {
    if (mounted) setState(() {});
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
    FocusScope.of(context).unfocus();
    setState(() {
      if (_mode == _CreationMode.groupDetails) {
        _mode = _CreationMode.groupMembers;
      } else {
        _mode = _CreationMode.menu;
        _selected.clear();
        _search.clear();
      }
    });
  }
}

class _MenuAction extends StatelessWidget {
  const _MenuAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 72,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: SizedBox(width: 34, child: Icon(icon, size: 24)),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      onTap: onTap,
    );
  }
}

class _SelectedPerson extends StatelessWidget {
  const _SelectedPerson({required this.user, required this.onRemove});

  final ChatNuUser user;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: onRemove,
      child: SizedBox(
        width: 54,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Column(
              children: <Widget>[
                _UserAvatar(user: user, size: 46),
                const SizedBox(height: 4),
                Text(
                  user.displayName.split(' ').first,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
            if (onRemove != null)
              const PositionedDirectional(
                top: -2,
                end: -2,
                child: CircleAvatar(
                  radius: 9,
                  backgroundColor: Colors.black,
                  child: Icon(Icons.close_rounded, size: 12, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
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
          padding: const EdgeInsets.all(28),
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
          minTileHeight: 68,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18),
          onTap: () => onTap(user),
          leading: _UserAvatar(user: user, size: 46),
          title: Text(user.displayName),
          subtitle: Text('@${user.username}'),
          trailing: groupMode
              ? Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                )
              : const Icon(Icons.chevron_right_rounded),
        );
      },
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.user, required this.size});

  final ChatNuUser user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    final url = user.avatarUrl?.trim();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: palette.glassMedium,
        image: url == null || url.isEmpty
            ? null
            : DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
      ),
      alignment: Alignment.center,
      child: url == null || url.isEmpty
          ? Text(user.initials, style: Theme.of(context).textTheme.labelLarge)
          : null,
    );
  }
}
