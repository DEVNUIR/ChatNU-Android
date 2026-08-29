import 'dart:async';

import 'package:chatnu/core/config/server_endpoint.dart';
import 'package:chatnu/core/glass/glass_components.dart';
import 'package:chatnu/core/localization/chatnu_strings.dart';
import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:chatnu/core/theme/chatnu_tokens.dart';
import 'package:chatnu/features/accounts/domain/chatnu_user.dart';
import 'package:chatnu/features/auth/application/session_controller.dart';
import 'package:chatnu/features/settings/application/appearance_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showProfileEditorSheet(
  BuildContext context, {
  required ChatNuUser user,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ProfileEditorSheet(user: user),
  );
}

Future<void> showServerManagerSheet(
  BuildContext context, {
  required ChatNuServerEndpoint endpoint,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ServerManagerSheet(endpoint: endpoint),
  );
}

Future<void> showWallpaperPickerSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => const _WallpaperPickerSheet(),
  );
}

class _ProfileEditorSheet extends ConsumerStatefulWidget {
  const _ProfileEditorSheet({required this.user});

  final ChatNuUser user;

  @override
  ConsumerState<_ProfileEditorSheet> createState() =>
      _ProfileEditorSheetState();
}

class _ProfileEditorSheetState extends ConsumerState<_ProfileEditorSheet> {
  late final TextEditingController _displayName;
  late final TextEditingController _bio;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _displayName = TextEditingController(text: widget.user.displayName);
    _bio = TextEditingController(text: widget.user.bio ?? '');
  }

  @override
  void dispose() {
    _displayName.dispose();
    _bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ChatNuStrings.of(context);
    final palette = context.chatNu;
    final user = ref.watch(sessionProvider).user ?? widget.user;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: GlassSheet(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        strings.isPersian ? 'ویرایش نمایه' : 'Edit profile',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                      onPressed: _busy ? null : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: ChatNuSpacing.md),
                Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      GlassAvatar(
                        label: user.displayName,
                        imageUrl: user.avatarUrl,
                        size: 88,
                      ),
                      PositionedDirectional(
                        end: -6,
                        bottom: -6,
                        child: Material(
                          color: palette.accentPrimary,
                          shape: const CircleBorder(),
                          child: IconButton(
                            tooltip: strings.isPersian
                                ? 'تغییر تصویر'
                                : 'Change avatar',
                            color: Colors.white,
                            onPressed: _busy ? null : _pickAvatar,
                            icon: const Icon(Icons.photo_camera_outlined),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: ChatNuSpacing.sm),
                if (user.avatarUrl?.isNotEmpty == true)
                  TextButton.icon(
                    onPressed: _busy ? null : _removeAvatar,
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: Text(
                      strings.isPersian ? 'حذف تصویر نمایه' : 'Remove avatar',
                    ),
                  ),
                const SizedBox(height: ChatNuSpacing.sm),
                GlassTextField(
                  controller: _displayName,
                  hintText: strings.isPersian ? 'نام نمایشی' : 'Display name',
                ),
                const SizedBox(height: ChatNuSpacing.sm),
                GlassTextField(
                  controller: _bio,
                  hintText: strings.isPersian ? 'دربارهٔ شما' : 'Bio',
                  maxLines: 3,
                ),
                const SizedBox(height: ChatNuSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(ChatNuSpacing.sm),
                  decoration: BoxDecoration(
                    color: palette.glassWeak,
                    borderRadius: BorderRadius.circular(ChatNuRadii.md),
                    border: Border.all(color: palette.borderSubtle),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.alternate_email_rounded, color: palette.textMuted),
                      const SizedBox(width: ChatNuSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('@${user.username}'),
                            const SizedBox(height: 2),
                            Text(
                              strings.isPersian
                                  ? 'نام کاربری فعلاً قابل تغییر نیست؛ به فضای هویت رمزنگاری دستگاه متصل است.'
                                  : 'Username is currently immutable because it participates in the device E2EE identity namespace.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: palette.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_error != null) ...<Widget>[
                  const SizedBox(height: ChatNuSpacing.sm),
                  Text(
                    _error!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.destructive,
                    ),
                  ),
                ],
                const SizedBox(height: ChatNuSpacing.md),
                GlassButton(
                  label: _busy
                      ? (strings.isPersian ? 'در حال ذخیره…' : 'Saving…')
                      : (strings.isPersian ? 'ذخیره' : 'Save changes'),
                  prominent: true,
                  icon: Icons.check_rounded,
                  onPressed: _busy ? null : _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await ref.read(sessionProvider.notifier).updateProfile(
      displayName: _displayName.text,
      bio: _bio.text,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
    if (error == null) Navigator.of(context).pop();
  }

  Future<void> _pickAvatar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      setState(() => _error = 'Unable to read the selected image.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await ref.read(sessionProvider.notifier).uploadAvatar(
      bytes: bytes,
      fileName: file.name,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  Future<void> _removeAvatar() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await ref.read(sessionProvider.notifier).removeAvatar();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
  }
}

class _ServerManagerSheet extends ConsumerStatefulWidget {
  const _ServerManagerSheet({required this.endpoint});

  final ChatNuServerEndpoint endpoint;

  @override
  ConsumerState<_ServerManagerSheet> createState() => _ServerManagerSheetState();
}

class _ServerManagerSheetState extends ConsumerState<_ServerManagerSheet> {
  late final TextEditingController _server;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _server = TextEditingController(text: widget.endpoint.enrollmentValue);
  }

  @override
  void dispose() {
    _server.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ChatNuStrings.of(context);
    final palette = context.chatNu;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: GlassSheet(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      strings.isPersian ? 'سرور ChatNU' : 'ChatNU server',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: _busy ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: ChatNuSpacing.md),
              GlassTextField(
                controller: _server,
                hintText: 'https://chat.example.com',
              ),
              const SizedBox(height: ChatNuSpacing.sm),
              Container(
                padding: const EdgeInsets.all(ChatNuSpacing.sm),
                decoration: BoxDecoration(
                  color: palette.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(ChatNuRadii.md),
                  border: Border.all(
                    color: palette.warning.withValues(alpha: 0.24),
                  ),
                ),
                child: Text(
                  strings.isPersian
                      ? 'تغییر سرور شما را از حساب فعلی خارج می‌کند و توکن‌های همان سرور را از دستگاه پاک می‌کند. کلید خصوصی یا توکن هرگز به سرور جدید فرستاده نمی‌شود.'
                      : 'Changing server signs out the current account and removes that server’s tokens from this device. Existing bearer tokens or private keys are never forwarded to the new server.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              if (_error != null) ...<Widget>[
                const SizedBox(height: ChatNuSpacing.sm),
                Text(
                  _error!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: palette.destructive,
                  ),
                ),
              ],
              const SizedBox(height: ChatNuSpacing.md),
              GlassButton(
                label: _busy
                    ? (strings.isPersian ? 'در حال تغییر…' : 'Switching…')
                    : (strings.isPersian ? 'تغییر سرور' : 'Switch server'),
                prominent: true,
                icon: Icons.dns_outlined,
                onPressed: _busy ? null : _switchServer,
              ),
              const SizedBox(height: ChatNuSpacing.xs),
              TextButton(
                onPressed: _busy ? null : _reset,
                child: Text(
                  strings.isPersian
                      ? 'بازگشت به api.devnu.ir'
                      : 'Reset to api.devnu.ir',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _switchServer() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await ref.read(sessionProvider.notifier).switchServer(_server.text);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  Future<void> _reset() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await ref.read(sessionProvider.notifier).resetServer();
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _busy = false;
      _error = error;
    });
  }
}

class _WallpaperPickerSheet extends ConsumerWidget {
  const _WallpaperPickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ChatNuStrings.of(context);
    final selected = ref.watch(
      appearanceProvider.select((value) => value.wallpaperStyle),
    );
    final choices = <ChatWallpaperStyle, ({String title, IconData icon})>{
      ChatWallpaperStyle.ambient: (
        title: strings.isPersian ? 'محیطی' : 'Ambient',
        icon: Icons.blur_circular_rounded,
      ),
      ChatWallpaperStyle.softGrid: (
        title: strings.isPersian ? 'شبکهٔ نرم' : 'Soft grid',
        icon: Icons.grid_4x4_rounded,
      ),
      ChatWallpaperStyle.midnight: (
        title: strings.isPersian ? 'نیمه‌شب' : 'Midnight',
        icon: Icons.dark_mode_outlined,
      ),
      ChatWallpaperStyle.solid: (
        title: strings.isPersian ? 'ساده' : 'Solid',
        icon: Icons.crop_square_rounded,
      ),
    };
    return GlassSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            strings.isPersian ? 'پس‌زمینهٔ گفتگو' : 'Chat background',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: ChatNuSpacing.sm),
          ...choices.entries.map(
            (entry) => RadioListTile<ChatWallpaperStyle>(
              value: entry.key,
              groupValue: selected,
              secondary: Icon(entry.value.icon),
              title: Text(entry.value.title),
              onChanged: (value) {
                if (value == null) return;
                unawaited(
                  ref.read(appearanceProvider.notifier).setWallpaperStyle(value),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
