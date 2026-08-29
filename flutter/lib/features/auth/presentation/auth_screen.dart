import 'dart:async';

import 'package:chatnu/core/di/app_providers.dart';
import 'package:chatnu/core/localization/chatnu_strings.dart';
import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:chatnu/core/theme/chatnu_tokens.dart';
import 'package:chatnu/features/auth/application/session_controller.dart';
import 'package:chatnu/shared/widgets/chatnu_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AuthMode { login, register, recover }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _displayName = TextEditingController();
  final _recoveryCode = TextEditingController();
  final _server = TextEditingController(text: 'https://api.devnu.ir/');

  AuthMode _mode = AuthMode.login;
  int _step = 0;
  bool _busy = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _displayName.dispose();
    _recoveryCode.dispose();
    _server.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final endpoint = ref.watch(serverEndpointProvider);
    final session = ref.watch(sessionProvider);
    if (_server.text == 'https://api.devnu.ir/' &&
        endpoint.enrollmentValue != _server.text) {
      _server.text = endpoint.enrollmentValue;
    }

    if (session.needsRecoveryCodeAcknowledgement) {
      return _RecoveryCodeCompletion(
        recoveryCode: session.recoveryCode!,
        onContinue: () =>
            ref.read(sessionProvider.notifier).acknowledgeRecoveryCode(),
      );
    }

    final palette = context.chatNu;
    return Scaffold(
      backgroundColor: palette.backgroundSecondary,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: <Widget>[
                _AuthTopBar(
                  canGoBack: _mode != AuthMode.login || _step > 0,
                  onBack: _goBack,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsetsDirectional.fromSTEB(24, 16, 24, 24),
                    child: AutofillGroup(
                      child: AnimatedSwitcher(
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 220),
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.035, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        ),
                        child: KeyedSubtree(
                          key: ValueKey<String>('${_mode.name}-$_step'),
                          child: _buildStep(),
                        ),
                      ),
                    ),
                  ),
                ),
                _BottomActionArea(
                  busy: _busy,
                  primaryLabel: _primaryLabel,
                  onPrimary: _busy ? null : _primaryAction,
                  secondary: _secondaryAction,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    return switch (_mode) {
      AuthMode.login => _buildLogin(),
      AuthMode.register => _buildRegisterStep(),
      AuthMode.recover => _buildRecoveryStep(),
    };
  }

  Widget _buildLogin() {
    final strings = ChatNuStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 20),
        _HeroTitle(
          eyebrow: strings.secureMessaging,
          title: strings.isPersian ? 'خوش برگشتید' : 'Welcome back',
          subtitle: strings.isPersian
              ? 'برای ادامه به گفتگوهای رمزگذاری‌شده وارد شوید.'
              : 'Sign in and pick up exactly where your secure conversations left off.',
        ),
        const SizedBox(height: 36),
        TextField(
          key: const Key('auth-username-field'),
          controller: _username,
          enabled: !_busy,
          autocorrect: false,
          textCapitalization: TextCapitalization.none,
          autofillHints: const <String>[AutofillHints.username],
          decoration: InputDecoration(
            labelText: strings.isPersian ? 'نام کاربری' : 'Username',
            hintText: 'yourname',
          ),
        ),
        const SizedBox(height: 14),
        _PasswordField(
          controller: _password,
          obscure: _obscurePassword,
          enabled: !_busy,
          label: strings.isPersian ? 'گذرواژه' : 'Password',
          onToggleVisibility: () =>
              setState(() => _obscurePassword = !_obscurePassword),
          onSubmitted: (_) => _primaryAction(),
        ),
        const SizedBox(height: 18),
        _ServerRow(onTap: _showServerSheet),
        _ErrorMessage(message: _error),
      ],
    );
  }

  Widget _buildRegisterStep() {
    final strings = ChatNuStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _StepProgress(step: _step, count: 3),
        const SizedBox(height: 30),
        if (_step == 0) ...<Widget>[
          _HeroTitle(
            eyebrow: strings.isPersian ? 'مرحله ۱ از ۳' : 'Step 1 of 3',
            title: strings.isPersian ? 'خودتان را معرفی کنید' : 'Create your profile',
            subtitle: strings.isPersian
                ? 'یک نام نمایشی و نام کاربری ساده انتخاب کنید. بعداً می‌توانید پروفایل را کامل‌تر کنید.'
                : 'Choose the name people will see and a simple username they can find you by.',
          ),
          const SizedBox(height: 34),
          TextField(
            key: const Key('auth-display-name-field'),
            controller: _displayName,
            enabled: !_busy,
            textCapitalization: TextCapitalization.words,
            autofillHints: const <String>[AutofillHints.name],
            decoration: InputDecoration(
              labelText: strings.isPersian ? 'نام نمایشی' : 'Display name',
              hintText: strings.isPersian ? 'مثلاً امیر' : 'e.g. Amir',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            key: const Key('auth-username-field'),
            controller: _username,
            enabled: !_busy,
            autocorrect: false,
            textCapitalization: TextCapitalization.none,
            autofillHints: const <String>[AutofillHints.newUsername],
            decoration: InputDecoration(
              labelText: strings.isPersian ? 'نام کاربری' : 'Username',
              hintText: 'amir',
              prefixText: '@',
            ),
          ),
        ] else if (_step == 1) ...<Widget>[
          _HeroTitle(
            eyebrow: strings.isPersian ? 'مرحله ۲ از ۳' : 'Step 2 of 3',
            title: strings.isPersian ? 'حساب را امن کنید' : 'Secure your account',
            subtitle: strings.isPersian
                ? 'گذرواژهٔ حساب را بسازید. کلید هویت E2EE دستگاه جداگانه و محلی ساخته می‌شود.'
                : 'Create your account password. Your device E2EE identity key is generated separately and stays local.',
          ),
          const SizedBox(height: 34),
          _PasswordField(
            key: const Key('auth-password-field'),
            controller: _password,
            obscure: _obscurePassword,
            enabled: !_busy,
            label: strings.isPersian ? 'گذرواژه' : 'Password',
            onToggleVisibility: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            onSubmitted: (_) => _primaryAction(),
          ),
          const SizedBox(height: 18),
          _SecurityCallout(
            icon: Icons.lock_outline_rounded,
            title: strings.isPersian ? 'رمزگذاری سرتاسری' : 'End-to-end identity',
            body: strings.isPersian
                ? 'کلید خصوصی هویت روی این دستگاه باقی می‌ماند و به سرور فرستاده نمی‌شود.'
                : 'The private identity key stays on this device and is never uploaded to the server.',
          ),
        ] else ...<Widget>[
          _HeroTitle(
            eyebrow: strings.isPersian ? 'مرحله ۳ از ۳' : 'Step 3 of 3',
            title: strings.isPersian ? 'آماده‌اید' : 'Ready to join',
            subtitle: strings.isPersian
                ? 'قبل از ساخت حساب، هویت و سروری را که به آن اعتماد می‌کنید مرور کنید.'
                : 'Review your identity and the server you are trusting before the account is created.',
          ),
          const SizedBox(height: 30),
          _ReviewRow(
            label: strings.isPersian ? 'نام' : 'Name',
            value: _displayName.text.trim(),
          ),
          _ReviewRow(
            label: strings.isPersian ? 'نام کاربری' : 'Username',
            value: '@${_username.text.trim().toLowerCase()}',
          ),
          _ReviewRow(
            label: strings.isPersian ? 'سرور' : 'Server',
            value: _server.text.trim(),
            onTap: _showServerSheet,
          ),
          const SizedBox(height: 18),
          _SecurityCallout(
            icon: Icons.key_rounded,
            title: strings.isPersian ? 'کد بازیابی' : 'Recovery code',
            body: strings.isPersian
                ? 'بعد از ساخت حساب، کد بازیابی یک‌بار نمایش داده می‌شود و تا ذخیره‌کردن آن وارد برنامه نمی‌شوید.'
                : 'After account creation, your recovery code is shown once and the app will wait for you to save it.',
          ),
        ],
        _ErrorMessage(message: _error),
      ],
    );
  }

  Widget _buildRecoveryStep() {
    final strings = ChatNuStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _StepProgress(step: _step, count: 2),
        const SizedBox(height: 30),
        if (_step == 0) ...<Widget>[
          _HeroTitle(
            eyebrow: strings.isPersian ? 'بازیابی امن' : 'Secure recovery',
            title: strings.isPersian ? 'حساب را پیدا کنید' : 'Find your account',
            subtitle: strings.isPersian
                ? 'نام کاربری و کد بازیابی‌ای را که هنگام ثبت‌نام ذخیره کردید وارد کنید.'
                : 'Enter your username and the recovery code you saved when the account was created.',
          ),
          const SizedBox(height: 34),
          TextField(
            key: const Key('auth-username-field'),
            controller: _username,
            enabled: !_busy,
            autocorrect: false,
            textCapitalization: TextCapitalization.none,
            decoration: InputDecoration(
              labelText: strings.isPersian ? 'نام کاربری' : 'Username',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            key: const Key('auth-recovery-code-field'),
            controller: _recoveryCode,
            enabled: !_busy,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: strings.isPersian ? 'کد بازیابی' : 'Recovery code',
            ),
          ),
        ] else ...<Widget>[
          _HeroTitle(
            eyebrow: strings.isPersian ? 'مرحله آخر' : 'Final step',
            title: strings.isPersian ? 'گذرواژهٔ تازه بسازید' : 'Create a new password',
            subtitle: strings.isPersian
                ? 'بازیابی گذرواژه را تغییر می‌دهد و نشست‌ها و دستگاه‌های فعلی را لغو می‌کند.'
                : 'Recovery changes the password and revokes the existing sessions and devices for this account.',
          ),
          const SizedBox(height: 34),
          _PasswordField(
            key: const Key('auth-password-field'),
            controller: _password,
            obscure: _obscurePassword,
            enabled: !_busy,
            label: strings.isPersian ? 'گذرواژهٔ جدید' : 'New password',
            onToggleVisibility: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            onSubmitted: (_) => _primaryAction(),
          ),
          const SizedBox(height: 18),
          _ServerRow(onTap: _showServerSheet),
        ],
        _ErrorMessage(message: _error),
      ],
    );
  }

  String get _primaryLabel {
    final fa = ChatNuStrings.of(context).isPersian;
    return switch (_mode) {
      AuthMode.login => fa ? 'ورود' : 'Sign in',
      AuthMode.register when _step < 2 => fa ? 'ادامه' : 'Continue',
      AuthMode.register => fa ? 'ساخت حساب' : 'Create account',
      AuthMode.recover when _step == 0 => fa ? 'ادامه' : 'Continue',
      AuthMode.recover => fa ? 'بازیابی حساب' : 'Recover account',
    };
  }

  Widget? get _secondaryAction {
    final strings = ChatNuStrings.of(context);
    if (_mode == AuthMode.login) {
      return Column(
        children: <Widget>[
          TextButton(
            key: const Key('auth-create-account'),
            onPressed: _busy ? null : () => _switchMode(AuthMode.register),
            child: Text(
              strings.isPersian
                  ? 'حساب ندارید؟ ساخت حساب'
                  : 'New to ChatNU? Create account',
            ),
          ),
          TextButton(
            key: const Key('auth-recover-account'),
            onPressed: _busy ? null : () => _switchMode(AuthMode.recover),
            child: Text(strings.isPersian ? 'بازیابی حساب' : 'Recover account'),
          ),
        ],
      );
    }
    return TextButton(
      key: const Key('auth-sign-in'),
      onPressed: _busy ? null : () => _switchMode(AuthMode.login),
      child: Text(
        strings.isPersian ? 'قبلاً حساب دارید؟ ورود' : 'Already have an account? Sign in',
      ),
    );
  }

  void _primaryAction() {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    switch (_mode) {
      case AuthMode.login:
        unawaited(_submitLogin());
      case AuthMode.register:
        if (_step == 0) {
          if (_displayName.text.trim().isEmpty || _username.text.trim().isEmpty) {
            setState(() => _error = 'Display name and username are required.');
            return;
          }
          setState(() => _step = 1);
        } else if (_step == 1) {
          if (_password.text.isEmpty) {
            setState(() => _error = 'Password is required.');
            return;
          }
          setState(() => _step = 2);
        } else {
          unawaited(_submitRegistration());
        }
      case AuthMode.recover:
        if (_step == 0) {
          if (_username.text.trim().isEmpty || _recoveryCode.text.trim().isEmpty) {
            setState(() => _error = 'Username and recovery code are required.');
            return;
          }
          setState(() => _step = 1);
        } else {
          unawaited(_submitRecovery());
        }
    }
  }

  void _switchMode(AuthMode mode) {
    setState(() {
      _mode = mode;
      _step = 0;
      _error = null;
      _password.clear();
      _recoveryCode.clear();
      _obscurePassword = true;
    });
  }

  void _goBack() {
    if (_step > 0) {
      setState(() {
        _step -= 1;
        _error = null;
      });
      return;
    }
    _switchMode(AuthMode.login);
  }

  Future<void> _submitLogin() async {
    await _runAuthAction(() async {
      final controller = ref.read(sessionProvider.notifier);
      return controller.login(
        username: _username.text,
        password: _password.text,
      );
    });
  }

  Future<void> _submitRegistration() async {
    await _runAuthAction(() async {
      final controller = ref.read(sessionProvider.notifier);
      return controller.register(
        username: _username.text,
        password: _password.text,
        displayName: _displayName.text,
      );
    });
  }

  Future<void> _submitRecovery() async {
    await _runAuthAction(() async {
      final controller = ref.read(sessionProvider.notifier);
      return controller.recover(
        username: _username.text,
        recoveryCode: _recoveryCode.text,
        newPassword: _password.text,
      );
    });
  }

  Future<void> _runAuthAction(Future<String?> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(serverEndpointProvider.notifier).configure(_server.text);
      final error = await action();
      if (mounted) setState(() => _error = error);
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showServerSheet() async {
    final strings = ChatNuStrings.of(context);
    final palette = context.chatNu;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          22,
          12,
          22,
          22 + MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.borderHighlight,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              strings.isPersian ? 'سرور ChatNU' : 'ChatNU server',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              strings.isPersian
                  ? 'این نشانی مرز اعتماد اتصال شماست. فقط سروری را وارد کنید که به آن اعتماد دارید.'
                  : 'This address is the trust boundary for your connection. Only use a server you trust.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            TextField(
              key: const Key('auth-server-field'),
              controller: _server,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: const InputDecoration(hintText: 'https://api.devnu.ir/'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                backgroundColor: palette.textPrimary,
                foregroundColor: palette.backgroundElevated,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: () => Navigator.of(sheetContext).pop(),
              child: Text(strings.isPersian ? 'انجام شد' : 'Done'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthTopBar extends StatelessWidget {
  const _AuthTopBar({required this.canGoBack, required this.onBack});

  final bool canGoBack;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 4),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 48,
            height: 48,
            child: canGoBack
                ? IconButton(
                    key: const Key('auth-back'),
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  )
                : const ChatNuMark(size: 34),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text('ChatNU', style: Theme.of(context).textTheme.titleLarge),
          ),
        ],
      ),
    );
  }
}

class _HeroTitle extends StatelessWidget {
  const _HeroTitle({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          eyebrow.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: palette.textMuted,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.9,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 36),
        ),
        const SizedBox(height: 12),
        Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.obscure,
    required this.enabled,
    required this.label,
    required this.onToggleVisibility,
    required this.onSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final bool obscure;
  final bool enabled;
  final String label;
  final VoidCallback onToggleVisibility;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: key,
      controller: controller,
      enabled: enabled,
      obscureText: obscure,
      enableSuggestions: false,
      autocorrect: false,
      autofillHints: const <String>[AutofillHints.password],
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          onPressed: enabled ? onToggleVisibility : null,
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          ),
        ),
      ),
    );
  }
}

class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.step, required this.count});

  final int step;
  final int count;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    return Row(
      children: List<Widget>.generate(count, (index) {
        final active = index <= step;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 4,
            margin: EdgeInsetsDirectional.only(end: index == count - 1 ? 0 : 6),
            decoration: BoxDecoration(
              color: active ? palette.textPrimary : palette.borderSubtle,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        );
      }),
    );
  }
}

class _ServerRow extends ConsumerWidget {
  const _ServerRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final endpoint = ref.watch(serverEndpointProvider);
    final palette = context.chatNu;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: <Widget>[
            Icon(Icons.lock_outline_rounded, size: 18, color: palette.success),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                endpoint.enrollmentValue,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              ChatNuStrings.of(context).isPersian ? 'تغییر' : 'Change',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value, this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: palette.borderSubtle)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: 96,
              child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (onTap != null) const Padding(
              padding: EdgeInsetsDirectional.only(start: 8),
              child: Icon(Icons.chevron_right_rounded, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecurityCallout extends StatelessWidget {
  const _SecurityCallout({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.glassWeak,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: palette.accentPrimary,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: Colors.black),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(body, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    final palette = context.chatNu;
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Text(
          message!,
          key: const Key('auth-error'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: palette.destructive,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _BottomActionArea extends StatelessWidget {
  const _BottomActionArea({
    required this.busy,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondary,
  });

  final bool busy;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final Widget? secondary;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 14, 24, 16),
      decoration: BoxDecoration(
        color: palette.backgroundElevated,
        border: Border(top: BorderSide(color: palette.borderSubtle)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FilledButton(
            key: const Key('auth-submit-button'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              backgroundColor: palette.textPrimary,
              foregroundColor: palette.backgroundElevated,
              textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: palette.backgroundElevated,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            onPressed: onPrimary,
            child: busy
                ? SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: palette.backgroundElevated,
                    ),
                  )
                : Text(primaryLabel),
          ),
          if (secondary != null) ...<Widget>[
            const SizedBox(height: 4),
            secondary!,
          ],
        ],
      ),
    );
  }
}

class _RecoveryCodeCompletion extends StatelessWidget {
  const _RecoveryCodeCompletion({
    required this.recoveryCode,
    required this.onContinue,
  });

  final String recoveryCode;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final strings = ChatNuStrings.of(context);
    final palette = context.chatNu;
    return Scaffold(
      backgroundColor: palette.backgroundSecondary,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: ChatNuMark(size: 36),
                  ),
                  const Spacer(),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: palette.accentPrimary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.key_rounded, color: Colors.black),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    strings.isPersian ? 'کد بازیابی را ذخیره کنید' : 'Save your recovery code',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 36),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    strings.isPersian
                        ? 'این کد برای بازیابی حساب لازم است. آن را در جای امنی خارج از ChatNU نگه دارید.'
                        : 'You need this code to recover the account. Store it somewhere safe outside ChatNU.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: palette.glassWeak,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: SelectableText(
                            recoveryCode,
                            key: const Key('recovery-code-result'),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontFeatures: const <FontFeature>[
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: strings.copy,
                          onPressed: () => unawaited(
                            Clipboard.setData(ClipboardData(text: recoveryCode)),
                          ),
                          icon: const Icon(Icons.copy_rounded),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  FilledButton(
                    key: const Key('recovery-code-acknowledge'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      backgroundColor: palette.textPrimary,
                      foregroundColor: palette.backgroundElevated,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: onContinue,
                    child: Text(strings.isPersian ? 'ذخیره کردم' : "I've saved it"),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
