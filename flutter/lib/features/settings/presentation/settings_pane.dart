import 'dart:async';

import 'package:chatnu/core/di/app_providers.dart';
import 'package:chatnu/core/glass/glass_components.dart';
import 'package:chatnu/core/glass/glass_surface.dart';
import 'package:chatnu/core/localization/chatnu_strings.dart';
import 'package:chatnu/core/localization/locale_controller.dart';
import 'package:chatnu/core/realtime/chatnu_realtime_client.dart';
import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:chatnu/core/theme/chatnu_tokens.dart';
import 'package:chatnu/features/auth/application/session_controller.dart';
import 'package:chatnu/features/home/application/demo_messenger_controller.dart';
import 'package:chatnu/features/settings/application/appearance_controller.dart';
import 'package:chatnu/features/settings/presentation/settings_action_sheets.dart';
import 'package:chatnu/features/settings/presentation/settings_support_sheets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsPane extends ConsumerWidget {
  const SettingsPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(messengerDemoProvider);
    final session = ref.watch(sessionProvider);
    final endpoint = ref.watch(serverEndpointProvider);
    final strings = ChatNuStrings.of(context);
    final palette = context.chatNu;
    final isDemo = ref.watch(appModeProvider) == ChatNuAppMode.demo;
    final user = session.user ?? state.currentUser;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: ChatNuSizing.contentMaxWidth,
          ),
          child: ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(
              ChatNuSpacing.md,
              ChatNuSpacing.sm,
              ChatNuSpacing.md,
              ChatNuSpacing.xl,
            ),
            children: <Widget>[
              GlassAppBar(
                title: Text(
                  strings.settings,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                subtitle: Text(
                  strings.isPersian
                      ? 'حساب، حریم خصوصی و تنظیمات برنامه'
                      : 'Account, privacy and app preferences',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: ChatNuSpacing.sm),
              _ProfileHero(
                displayName: user.displayName,
                username: user.username,
                avatarUrl: user.avatarUrl,
                bio: user.bio,
                serverLabel: endpoint.restUri.host,
                onTap: () =>
                    unawaited(showProfileEditorSheet(context, user: user)),
              ),
              if (session.offline) ...<Widget>[
                const SizedBox(height: ChatNuSpacing.sm),
                _NoticeTile(
                  icon: Icons.cloud_off_outlined,
                  color: palette.warning,
                  title: strings.offlineSession,
                  subtitle: strings.offlineSessionDetail,
                ),
              ],
              const SizedBox(height: ChatNuSpacing.sm),
              const _AppearanceStudio(),
              const SizedBox(height: ChatNuSpacing.sm),
              _SettingsSection(
                title: strings.account,
                children: <Widget>[
                  _SettingsTile(
                    icon: Icons.person_outline_rounded,
                    title: strings.isPersian ? 'نمایهٔ شما' : 'Your profile',
                    subtitle: strings.isPersian
                        ? 'تصویر نمایه، نام نمایشی و توضیح حساب'
                        : 'Avatar, display name and account bio',
                    onTap: () =>
                        unawaited(showProfileEditorSheet(context, user: user)),
                  ),
                  _SettingsTile(
                    icon: Icons.switch_account_rounded,
                    title: strings.isPersian
                        ? 'حساب‌ها و سرورها'
                        : 'Accounts & servers',
                    subtitle: strings.isPersian
                        ? 'سرور فعال ChatNU و ورود به حساب را مدیریت کنید'
                        : 'Manage your active ChatNU server and sign-in',
                    onTap: () => unawaited(
                      showServerManagerSheet(context, endpoint: endpoint),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ChatNuSpacing.sm),
              _SettingsSection(
                title: strings.isPersian ? 'گفت‌وگو و رسانه' : 'Chats & media',
                children: <Widget>[
                  _SettingsTile(
                    icon: Icons.photo_library_outlined,
                    title: strings.isPersian
                        ? 'رسانه و فایل‌ها'
                        : 'Media & files',
                    subtitle: strings.isPersian
                        ? 'تصویر، ویدیو، صدا، موقعیت و فایل؛ رمزگذاری پیش از ارسال'
                        : 'Images, video, audio, location and files; encrypted before sending',
                  ),
                  _SettingsTile(
                    icon: Icons.video_call_outlined,
                    title: strings.isPersian ? 'تماس‌ها' : 'Calls',
                    subtitle: strings.isPersian
                        ? 'تماس صوتی و تصویری امن یک‌به‌یک'
                        : 'Secure 1:1 voice and video calls',
                  ),
                ],
              ),
              const SizedBox(height: ChatNuSpacing.sm),
              _SettingsSection(
                title: strings.privacySecurity,
                children: <Widget>[
                  _SettingsTile(
                    icon: Icons.lock_outline_rounded,
                    iconColor: palette.success,
                    title: strings.isPersian
                        ? 'رمزگذاری سرتاسری'
                        : 'End-to-end encryption',
                    subtitle: strings.isPersian
                        ? 'محتوای پیام روی دستگاه‌های شما رمزگذاری و رمزگشایی می‌شود.'
                        : 'Message content is encrypted and decrypted on your devices.',
                  ),
                  _SettingsTile(
                    icon: Icons.attach_file_rounded,
                    title: strings.isPersian
                        ? 'پیوست‌های رمزگذاری‌شده'
                        : 'Encrypted attachments',
                    subtitle: strings.isPersian
                        ? 'فایل‌ها پیش از آپلود رمزگذاری می‌شوند.'
                        : 'Files are encrypted before upload.',
                  ),
                ],
              ),
              const SizedBox(height: ChatNuSpacing.sm),
              _SettingsSection(
                title: strings.isPersian ? 'پیشرفته' : 'Advanced',
                children: <Widget>[
                  _SettingsTile(
                    key: const Key('settings-advanced'),
                    icon: Icons.tune_rounded,
                    title: strings.isPersian
                        ? 'جزئیات فنی'
                        : 'Technical details',
                    subtitle: strings.isPersian
                        ? 'اتصال، پروتکل رمزگذاری و معماری تماس'
                        : 'Connection, encryption protocol and call architecture',
                    onTap: () => unawaited(
                      _showAdvancedSettingsSheet(
                        context,
                        ref,
                        state: state,
                        endpointLabel: endpoint.hostLabel,
                        emergencyTls: endpoint.usesEmergencyTls,
                        isDemo: isDemo,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ChatNuSpacing.sm),
              _SettingsSection(
                title: strings.isPersian ? 'راهنما و درباره' : 'Help & about',
                children: <Widget>[
                  _SettingsTile(
                    icon: Icons.auto_awesome_rounded,
                    title: strings.isPersian
                        ? 'راهنمای شروع'
                        : 'Getting started',
                    subtitle: strings.isPersian
                        ? 'هویت، سرور، افراد، رسانه و تماس'
                        : 'Identity, server, people, media and calls',
                    onTap: () => unawaited(showGettingStartedSheet(context)),
                  ),
                  _SettingsTile(
                    icon: Icons.help_outline_rounded,
                    title: strings.isPersian ? 'پرسش‌های متداول' : 'FAQ',
                    subtitle: strings.isPersian
                        ? 'پاسخ‌های کوتاه درباره امنیت و قابلیت‌ها'
                        : 'Short answers about security and product behavior',
                    onTap: () => unawaited(showFaqSheet(context)),
                  ),
                  _SettingsTile(
                    icon: Icons.info_outline_rounded,
                    title: strings.isPersian
                        ? 'دربارهٔ ChatNU'
                        : 'About ChatNU',
                    subtitle: 'Developed by devnu.ir',
                    onTap: () => unawaited(showAboutSheet(context)),
                  ),
                ],
              ),
              if (!isDemo) ...<Widget>[
                const SizedBox(height: ChatNuSpacing.md),
                GlassButton(
                  label: strings.logout,
                  icon: Icons.logout_rounded,
                  destructive: true,
                  onPressed: () =>
                      unawaited(ref.read(sessionProvider.notifier).logout()),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static IconData _connectionIcon(RealtimeConnectionStatus status) =>
      switch (status) {
        RealtimeConnectionStatus.connected => Icons.cloud_done_outlined,
        RealtimeConnectionStatus.connecting => Icons.cloud_sync_outlined,
        RealtimeConnectionStatus.disconnected => Icons.cloud_off_outlined,
      };

  static String _connectionLabel(
    ChatNuStrings strings,
    RealtimeConnectionStatus status,
  ) => switch (status) {
    RealtimeConnectionStatus.connected => strings.realtimeConnected,
    RealtimeConnectionStatus.connecting => strings.realtimeConnecting,
    RealtimeConnectionStatus.disconnected => strings.realtimeDisconnected,
  };
}

Future<void> _showAdvancedSettingsSheet(
  BuildContext context,
  WidgetRef ref, {
  required MessengerDemoState state,
  required String endpointLabel,
  required bool emergencyTls,
  required bool isDemo,
}) async {
  final strings = ChatNuStrings.of(context);
  final palette = context.chatNu;
  await showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => GlassSheet(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    strings.isPersian ? 'جزئیات فنی' : 'Technical details',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: strings.cancel,
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: ChatNuSpacing.xs),
            _SettingsTile(
              icon: SettingsPane._connectionIcon(state.realtimeStatus),
              title: SettingsPane._connectionLabel(
                strings,
                state.realtimeStatus,
              ),
              subtitle: endpointLabel,
              trailing: IconButton(
                tooltip: strings.refresh,
                onPressed: isDemo
                    ? null
                    : () => unawaited(
                        ref
                            .read(messengerDemoProvider.notifier)
                            .refreshConversations(),
                      ),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ),
            _SettingsTile(
              icon: Icons.key_rounded,
              title: 'ChatNU Device Envelope v2',
              subtitle: strings.isPersian
                  ? 'پروتکل فعلی ChatNU است و Signal Protocol نیست.'
                  : 'This is ChatNU’s current device-envelope protocol, not Signal Protocol.',
            ),
            _SettingsTile(
              icon: Icons.hub_outlined,
              title: strings.isPersian ? 'معماری تماس' : 'Call architecture',
              subtitle: strings.isPersian
                  ? 'سیگنالینگ فعلی یک‌به‌یک است؛ تماس گروهی به پشتیبانی چندنفره/SFU در سرور نیاز دارد.'
                  : 'Current signaling is 1:1; group meetings require explicit multiparty/SFU server support.',
            ),
            if (emergencyTls)
              _SettingsTile(
                icon: Icons.security_outlined,
                iconColor: palette.warning,
                title: strings.isPersian
                    ? 'سازگاری TLS اضطراری'
                    : 'Emergency TLS compatibility',
                subtitle: strings.isPersian
                    ? 'ثبت CA ذخیره است، اما Flutter تا برابری بررسی pin بومی با Android این انتقال را رد می‌کند.'
                    : 'Saved CA enrollment remains blocked until native CA-pin verification reaches Android parity.',
              ),
          ],
        ),
      ),
    ),
  );
}

class _AppearanceStudio extends ConsumerWidget {
  const _AppearanceStudio();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(appearanceProvider);
    final locale = ref.watch(localeProvider);
    final strings = ChatNuStrings.of(context);
    final palette = context.chatNu;
    final wallpaperLabel = switch (appearance.wallpaperStyle) {
      ChatWallpaperStyle.ambient => strings.isPersian ? 'محیطی' : 'Ambient',
      ChatWallpaperStyle.softGrid =>
        strings.isPersian ? 'شبکهٔ نرم' : 'Soft grid',
      ChatWallpaperStyle.midnight => strings.isPersian ? 'نیمه‌شب' : 'Midnight',
      ChatWallpaperStyle.solid => strings.isPersian ? 'ساده' : 'Solid',
    };

    return GlassPanel(
      variant: GlassVariant.medium,
      blur: true,
      radius: ChatNuRadii.lg,
      padding: const EdgeInsets.all(ChatNuSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(ChatNuRadii.md),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      palette.accentPrimary,
                      palette.accentSecondary,
                    ],
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: palette.accentPrimary.withValues(alpha: 0.28),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: ChatNuSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      strings.appearance,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.isPersian
                          ? 'ظاهر ChatNU را بدون به‌هم‌ریختن خوانایی شخصی‌سازی کنید'
                          : 'Tune ChatNU without sacrificing clarity',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ChatNuSpacing.ml),
          _PreferenceCaption(
            label: strings.isPersian ? 'پوسته' : 'Theme',
            icon: Icons.contrast_rounded,
          ),
          const SizedBox(height: ChatNuSpacing.xs),
          GlassSegmentedControl<ThemeMode>(
            value: appearance.themeMode,
            onChanged: (mode) => unawaited(
              ref.read(appearanceProvider.notifier).setThemeMode(mode),
            ),
            items: <ThemeMode, String>{
              ThemeMode.system: strings.systemTheme,
              ThemeMode.light: strings.lightTheme,
              ThemeMode.dark: strings.darkTheme,
            },
          ),
          const SizedBox(height: ChatNuSpacing.md),
          _PreferenceCaption(
            label: strings.isPersian ? 'جلوه‌های بصری' : 'Visual effects',
            icon: Icons.blur_on_rounded,
          ),
          const SizedBox(height: ChatNuSpacing.xs),
          GlassSegmentedControl<GlassEffectLevel>(
            value: appearance.glassEffectLevel,
            onChanged: (level) => unawaited(
              ref.read(appearanceProvider.notifier).setGlassEffectLevel(level),
            ),
            items: <GlassEffectLevel, String>{
              GlassEffectLevel.full: strings.glassFull,
              GlassEffectLevel.balanced: strings.glassBalanced,
              GlassEffectLevel.reduced: strings.glassReduced,
            },
          ),
          const SizedBox(height: ChatNuSpacing.md),
          _PreferenceCaption(
            label: strings.isPersian ? 'پس‌زمینهٔ گفتگو' : 'Chat background',
            icon: Icons.wallpaper_rounded,
          ),
          const SizedBox(height: ChatNuSpacing.xs),
          InkWell(
            borderRadius: BorderRadius.circular(ChatNuRadii.md),
            onTap: () => unawaited(showWallpaperPickerSheet(context)),
            child: Ink(
              height: 76,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(ChatNuRadii.md),
                border: Border.all(color: palette.borderSubtle),
                gradient: LinearGradient(
                  begin: AlignmentDirectional.topStart,
                  end: AlignmentDirectional.bottomEnd,
                  colors: <Color>[
                    palette.accentPrimary.withValues(alpha: 0.24),
                    palette.accentSecondary.withValues(alpha: 0.13),
                    palette.glassWeak,
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ChatNuSpacing.md,
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: <Color>[
                            palette.accentPrimary,
                            palette.accentCyan,
                            palette.accentSecondary,
                            palette.accentPrimary,
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: ChatNuSpacing.sm),
                    Expanded(
                      child: Text(
                        wallpaperLabel,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Icon(
                      Directionality.of(context) == TextDirection.rtl
                          ? Icons.chevron_left_rounded
                          : Icons.chevron_right_rounded,
                      color: palette.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: ChatNuSpacing.md),
          _PreferenceCaption(
            label: strings.isPersian ? 'زبان' : 'Language',
            icon: Icons.translate_rounded,
          ),
          const SizedBox(height: ChatNuSpacing.xs),
          GlassSegmentedControl<ChatNuLocalePreference>(
            value: locale.preference,
            onChanged: (preference) => unawaited(
              ref.read(localeProvider.notifier).setPreference(preference),
            ),
            items: const <ChatNuLocalePreference, String>{
              ChatNuLocalePreference.system: 'System',
              ChatNuLocalePreference.english: 'English',
              ChatNuLocalePreference.persian: 'فارسی',
            },
          ),
        ],
      ),
    );
  }
}

class _PreferenceCaption extends StatelessWidget {
  const _PreferenceCaption({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    return Row(
      children: <Widget>[
        Icon(icon, size: 17, color: palette.accentPrimary),
        const SizedBox(width: ChatNuSpacing.xs),
        Text(label, style: Theme.of(context).textTheme.labelLarge),
      ],
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.displayName,
    required this.username,
    required this.avatarUrl,
    required this.bio,
    required this.serverLabel,
    required this.onTap,
  });

  final String displayName;
  final String username;
  final String? avatarUrl;
  final String? bio;
  final String serverLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    final url = avatarUrl?.trim();
    return GlassPanel(
      variant: GlassVariant.strong,
      blur: true,
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(ChatNuRadii.lg),
        onTap: onTap,
        child: Stack(
          children: <Widget>[
            PositionedDirectional(
              top: -60,
              end: -42,
              child: IgnorePointer(
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: <Color>[
                        palette.accentPrimary.withValues(alpha: 0.26),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(ChatNuSpacing.md),
              child: Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[
                          palette.accentCyan,
                          palette.accentPrimary,
                          palette.accentSecondary,
                        ],
                      ),
                    ),
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: palette.backgroundElevated,
                        image: url == null || url.isEmpty
                            ? null
                            : DecorationImage(
                                image: NetworkImage(url),
                                fit: BoxFit.cover,
                              ),
                      ),
                      alignment: Alignment.center,
                      child: url == null || url.isEmpty
                          ? Text(
                              _initials(displayName),
                              style: Theme.of(context).textTheme.titleLarge,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: ChatNuSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          displayName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@$username',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: palette.textMuted),
                        ),
                        if (bio?.trim().isNotEmpty == true) ...<Widget>[
                          const SizedBox(height: 5),
                          Text(
                            bio!.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: ChatNuSpacing.xs,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: palette.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              ChatNuRadii.pill,
                            ),
                            border: Border.all(
                              color: palette.success.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: palette.success,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  serverLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(color: palette.textSecondary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.chevron_left_rounded
                        : Icons.chevron_right_rounded,
                    color: palette.textMuted,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _initials(String value) {
    final words = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((item) => item.isNotEmpty);
    final chars = words
        .take(2)
        .map((item) => item.characters.first.toUpperCase())
        .join();
    return chars.isEmpty ? '?' : chars;
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    return GlassPanel(
      variant: GlassVariant.weak,
      radius: ChatNuRadii.lg,
      padding: const EdgeInsets.symmetric(vertical: ChatNuSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              ChatNuSpacing.md,
              ChatNuSpacing.sm,
              ChatNuSpacing.md,
              ChatNuSpacing.xs,
            ),
            child: Text(
              title,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: palette.accentPrimary, letterSpacing: 0.2),
            ),
          ),
          for (var index = 0; index < children.length; index++) ...<Widget>[
            children[index],
            if (index != children.length - 1)
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: 66,
                  end: ChatNuSpacing.md,
                ),
                child: Divider(
                  color: palette.borderSubtle.withValues(alpha: 0.65),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor,
    this.onTap,
    this.trailing,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color? iconColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    final chevron = Directionality.of(context) == TextDirection.rtl
        ? Icons.chevron_left_rounded
        : Icons.chevron_right_rounded;
    return ListTile(
      minTileHeight: 72,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ChatNuRadii.sm),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              (iconColor ?? palette.accentPrimary).withValues(alpha: 0.18),
              palette.accentSecondary.withValues(alpha: 0.08),
            ],
          ),
          border: Border.all(
            color: (iconColor ?? palette.accentPrimary).withValues(alpha: 0.16),
          ),
        ),
        child: Icon(icon, size: 20, color: iconColor ?? palette.accentPrimary),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(color: palette.textPrimary, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing:
          trailing ??
          (onTap == null ? null : Icon(chevron, color: palette.textMuted)),
      onTap: onTap,
    );
  }
}

class _NoticeTile extends StatelessWidget {
  const _NoticeTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => GlassPanel(
    variant: GlassVariant.weak,
    padding: EdgeInsets.zero,
    child: ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      subtitle: Text(subtitle),
    ),
  );
}
