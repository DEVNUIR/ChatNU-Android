import 'dart:async';

import 'package:chatnu/core/di/app_providers.dart';
import 'package:chatnu/core/localization/chatnu_strings.dart';
import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:chatnu/features/auth/application/session_controller.dart';
import 'package:chatnu/shared/widgets/chatnu_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AuthMode { welcome, login, register, recover }

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

  AuthMode _mode = AuthMode.welcome;
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
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: <Widget>[
                _AuthTopBar(
                  canGoBack: _mode != AuthMode.welcome,
                  onBack: _goBack,
                  onServer: _showServerSheet,
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 220),
                    transitionBuilder: (child, animation) {
                      final slide =
                          Tween<Offset>(
                            begin: const Offset(0.06, 0),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            ),
                          );
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(position: slide, child: child),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey<String>('${_mode.name}-$_step'),
                      child: _buildCurrentScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() => switch (_mode) {
    AuthMode.welcome => _buildWelcome(),
    AuthMode.login => _buildLogin(),
    AuthMode.register => _buildRegister(),
    AuthMode.recover => _buildRecovery(),
  };

  Widget _screen({
    required Widget body,
    required String primaryLabel,
    required VoidCallback? onPrimary,
    Widget? footer,
    int? step,
    int? stepCount,
  }) {
    return Column(
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsetsDirectional.fromSTEB(24, 8, 24, 20),
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (step != null && stepCount != null) ...<Widget>[
                    _StepProgress(step: step, count: stepCount),
                    const SizedBox(height: 34),
                  ],
                  body,
                  _ErrorMessage(message: _error),
                ],
              ),
            ),
          ),
        ),
        _BottomActionArea(
          busy: _busy,
          primaryLabel: primaryLabel,
          onPrimary: _busy ? null : onPrimary,
          secondary: footer,
        ),
      ],
    );
  }

  Widget _buildWelcome() {
    final strings = ChatNuStrings.of(context);
    final palette = context.chatNu;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 10, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Spacer(flex: 2),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: palette.accentPrimary,
                borderRadius: BorderRadius.circular(26),
              ),
              alignment: Alignment.center,
              child: const ChatNuMark(size: 48),
            ),
          ),
          const SizedBox(height: 34),
          Text(
            strings.isPersian
                ? 'گفتگو، ساده و امن.'
                : 'Chat, simply and securely.',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontSize: 42,
              height: 1.05,
              letterSpacing: -1.8,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            strings.isPersian
                ? 'ChatNU یک پیام‌رسان واقعی با رمزگذاری سرتاسری دستگاهی است. بدون دستیار هوش مصنوعی، بدون شلوغی.'
                : 'ChatNU is a real device-encrypted messenger. No AI assistant, no feed, no clutter.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: palette.textSecondary,
              fontSize: 17,
            ),
          ),
          const Spacer(flex: 3),
          FilledButton(
            key: const Key('auth-create-account'),
            style: _blackButtonStyle(context),
            onPressed: () => _switchMode(AuthMode.register),
            child: Text(strings.isPersian ? 'ساخت حساب' : 'Create account'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            key: const Key('auth-login-entry'),
            style: _outlineButtonStyle(context),
            onPressed: () => _switchMode(AuthMode.login),
            child: Text(strings.isPersian ? 'ورود' : 'Log in'),
          ),
          const SizedBox(height: 8),
          TextButton(
            key: const Key('auth-recover-account'),
            onPressed: () => _switchMode(AuthMode.recover),
            child: Text(strings.isPersian ? 'بازیابی حساب' : 'Recover account'),
          ),
        ],
      ),
    );
  }

  Widget _buildLogin() {
    final strings = ChatNuStrings.of(context);
    return _screen(
      primaryLabel: strings.isPersian ? 'ورود' : 'Log in',
      onPrimary: _primaryAction,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _HeroTitle(
            title: strings.isPersian ? 'خوش برگشتید' : 'Welcome back',
            subtitle: strings.isPersian
                ? 'نام کاربری و گذرواژه‌تان را وارد کنید.'
                : 'Enter your username and password to continue.',
          ),
          const SizedBox(height: 38),
          _FieldLabel(strings.isPersian ? 'نام کاربری' : 'Username'),
          const SizedBox(height: 8),
          TextField(
            key: const Key('auth-username-field'),
            controller: _username,
            enabled: !_busy,
            autocorrect: false,
            textCapitalization: TextCapitalization.none,
            autofillHints: const <String>[AutofillHints.username],
            decoration: const InputDecoration(hintText: 'username'),
          ),
          const SizedBox(height: 18),
          _FieldLabel(strings.isPersian ? 'گذرواژه' : 'Password'),
          const SizedBox(height: 8),
          _PasswordField(
            key: const Key('auth-password-field'),
            controller: _password,
            obscure: _obscurePassword,
            enabled: !_busy,
            onToggleVisibility: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            onSubmitted: (_) => _primaryAction(),
          ),
        ],
      ),
      footer: TextButton(
        onPressed: _busy ? null : () => _switchMode(AuthMode.recover),
        child: Text(
          strings.isPersian ? 'گذرواژه را فراموش کردید؟' : 'Forgot password?',
        ),
      ),
    );
  }

  Widget _buildRegister() {
    final strings = ChatNuStrings.of(context);
    const count = 4;
    return _screen(
      step: _step,
      stepCount: count,
      primaryLabel: _step == count - 1
          ? (strings.isPersian ? 'ساخت حساب' : 'Create account')
          : (strings.isPersian ? 'ادامه' : 'Continue'),
      onPrimary: _primaryAction,
      body: switch (_step) {
        0 => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _HeroTitle(
              title: strings.isPersian
                  ? 'اسمتان چیست؟'
                  : 'What should people call you?',
              subtitle: strings.isPersian
                  ? 'این نام در بالای گفتگوها و گروه‌ها دیده می‌شود.'
                  : 'This is the name people will see in chats and groups.',
            ),
            const SizedBox(height: 42),
            _FieldLabel(strings.isPersian ? 'نام نمایشی' : 'Display name'),
            const SizedBox(height: 8),
            TextField(
              key: const Key('auth-display-name-field'),
              controller: _displayName,
              autofocus: true,
              enabled: !_busy,
              textCapitalization: TextCapitalization.words,
              autofillHints: const <String>[AutofillHints.name],
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                hintText: strings.isPersian ? 'مثلاً امیر' : 'e.g. Amir',
              ),
              onSubmitted: (_) => _primaryAction(),
            ),
          ],
        ),
        1 => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _HeroTitle(
              title: strings.isPersian
                  ? 'یک نام کاربری انتخاب کنید'
                  : 'Pick a username',
              subtitle: strings.isPersian
                  ? 'دوستانتان با این نام شما را پیدا می‌کنند.'
                  : 'People use this to find you on ChatNU.',
            ),
            const SizedBox(height: 42),
            _FieldLabel(strings.isPersian ? 'نام کاربری' : 'Username'),
            const SizedBox(height: 8),
            TextField(
              key: const Key('auth-username-field'),
              controller: _username,
              autofocus: true,
              enabled: !_busy,
              autocorrect: false,
              textCapitalization: TextCapitalization.none,
              autofillHints: const <String>[AutofillHints.username],
              decoration: const InputDecoration(
                hintText: 'username',
                prefixText: '@',
              ),
              onSubmitted: (_) => _primaryAction(),
            ),
          ],
        ),
        2 => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _HeroTitle(
              title: strings.isPersian
                  ? 'حسابتان را امن کنید'
                  : 'Secure your account',
              subtitle: strings.isPersian
                  ? 'یک گذرواژه قوی بسازید. کلید خصوصی هویت دستگاه جداگانه روی همین دستگاه ساخته می‌شود.'
                  : 'Create a strong password. Your device identity key is generated separately and stays on this device.',
            ),
            const SizedBox(height: 42),
            _FieldLabel(strings.isPersian ? 'گذرواژه' : 'Password'),
            const SizedBox(height: 8),
            _PasswordField(
              key: const Key('auth-password-field'),
              controller: _password,
              obscure: _obscurePassword,
              enabled: !_busy,
              onToggleVisibility: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              onSubmitted: (_) => _primaryAction(),
            ),
            const SizedBox(height: 22),
            _SecurityNote(
              title: strings.isPersian
                  ? 'رمزگذاری سرتاسری دستگاهی'
                  : 'Device end-to-end encryption',
              body: strings.isPersian
                  ? 'کلید خصوصی هویت شما به سرور ارسال نمی‌شود.'
                  : 'Your private identity key is never uploaded to the server.',
            ),
          ],
        ),
        _ => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _HeroTitle(
              title: strings.isPersian ? 'همه‌چیز آماده است' : 'You’re ready',
              subtitle: strings.isPersian
                  ? 'قبل از ساخت حساب، اطلاعاتتان را یک‌بار بررسی کنید.'
                  : 'Check the details once before we create your account.',
            ),
            const SizedBox(height: 30),
            _ProfileReview(
              displayName: _displayName.text.trim(),
              username: _username.text.trim(),
            ),
            const SizedBox(height: 20),
            _ServerRow(onTap: _showServerSheet),
            const SizedBox(height: 18),
            _SecurityNote(
              title: strings.isPersian
                  ? 'کد بازیابی را ذخیره کنید'
                  : 'Save the recovery code',
              body: strings.isPersian
                  ? 'بعد از ثبت‌نام، کد بازیابی یک‌بار نمایش داده می‌شود.'
                  : 'After signup, ChatNU shows your recovery code once before entering the app.',
            ),
          ],
        ),
      },
      footer: TextButton(
        onPressed: _busy ? null : () => _switchMode(AuthMode.login),
        child: Text(
          strings.isPersian
              ? 'حساب دارید؟ ورود'
              : 'Already have an account? Log in',
        ),
      ),
    );
  }

  Widget _buildRecovery() {
    final strings = ChatNuStrings.of(context);
    return _screen(
      step: _step,
      stepCount: 2,
      primaryLabel: _step == 0
          ? (strings.isPersian ? 'ادامه' : 'Continue')
          : (strings.isPersian ? 'بازیابی حساب' : 'Recover account'),
      onPrimary: _primaryAction,
      body: _step == 0
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _HeroTitle(
                  title: strings.isPersian
                      ? 'حسابتان را پیدا کنید'
                      : 'Find your account',
                  subtitle: strings.isPersian
                      ? 'نام کاربری و کد بازیابی‌ای که هنگام ثبت‌نام ذخیره کردید وارد کنید.'
                      : 'Enter your username and the recovery code you saved during signup.',
                ),
                const SizedBox(height: 38),
                _FieldLabel(strings.isPersian ? 'نام کاربری' : 'Username'),
                const SizedBox(height: 8),
                TextField(
                  key: const Key('auth-username-field'),
                  controller: _username,
                  enabled: !_busy,
                  autocorrect: false,
                  textCapitalization: TextCapitalization.none,
                  decoration: const InputDecoration(hintText: 'username'),
                ),
                const SizedBox(height: 18),
                _FieldLabel(strings.isPersian ? 'کد بازیابی' : 'Recovery code'),
                const SizedBox(height: 8),
                TextField(
                  key: const Key('auth-recovery-code-field'),
                  controller: _recoveryCode,
                  enabled: !_busy,
                  autocorrect: false,
                  decoration: const InputDecoration(hintText: 'XXXX-XXXX-XXXX'),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _HeroTitle(
                  title: strings.isPersian
                      ? 'گذرواژه تازه بسازید'
                      : 'Create a new password',
                  subtitle: strings.isPersian
                      ? 'بازیابی گذرواژه را تغییر می‌دهد و نشست‌ها و دستگاه‌های فعلی را لغو می‌کند.'
                      : 'Recovery changes the password and revokes existing sessions and devices.',
                ),
                const SizedBox(height: 38),
                _FieldLabel(
                  strings.isPersian ? 'گذرواژه جدید' : 'New password',
                ),
                const SizedBox(height: 8),
                _PasswordField(
                  key: const Key('auth-password-field'),
                  controller: _password,
                  obscure: _obscurePassword,
                  enabled: !_busy,
                  onToggleVisibility: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  onSubmitted: (_) => _primaryAction(),
                ),
              ],
            ),
    );
  }

  void _primaryAction() {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);

    if (_mode == AuthMode.login) {
      if (_username.text.trim().isEmpty || _password.text.isEmpty) {
        setState(() => _error = 'Username and password are required.');
        return;
      }
      unawaited(_submitLogin());
      return;
    }

    if (_mode == AuthMode.register) {
      if (_step == 0) {
        if (_displayName.text.trim().isEmpty) {
          setState(() => _error = 'Display name is required.');
          return;
        }
        setState(() => _step = 1);
        return;
      }
      if (_step == 1) {
        if (_username.text.trim().isEmpty) {
          setState(() => _error = 'Username is required.');
          return;
        }
        setState(() => _step = 2);
        return;
      }
      if (_step == 2) {
        if (_password.text.isEmpty) {
          setState(() => _error = 'Password is required.');
          return;
        }
        setState(() => _step = 3);
        return;
      }
      unawaited(_submitRegistration());
      return;
    }

    if (_mode == AuthMode.recover) {
      if (_step == 0) {
        if (_username.text.trim().isEmpty ||
            _recoveryCode.text.trim().isEmpty) {
          setState(() => _error = 'Username and recovery code are required.');
          return;
        }
        setState(() => _step = 1);
        return;
      }
      if (_password.text.isEmpty) {
        setState(() => _error = 'New password is required.');
        return;
      }
      unawaited(_submitRecovery());
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
    _switchMode(AuthMode.welcome);
  }

  Future<void> _submitLogin() async {
    await _runAuthAction(() async {
      return ref
          .read(sessionProvider.notifier)
          .login(username: _username.text, password: _password.text);
    });
  }

  Future<void> _submitRegistration() async {
    await _runAuthAction(() async {
      return ref
          .read(sessionProvider.notifier)
          .register(
            username: _username.text,
            password: _password.text,
            displayName: _displayName.text,
          );
    });
  }

  Future<void> _submitRecovery() async {
    await _runAuthAction(() async {
      return ref
          .read(sessionProvider.notifier)
          .recover(
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
      barrierColor: Colors.black.withValues(alpha: 0.34),
      builder: (sheetContext) => Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          22,
          10,
          22,
          22 + MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.borderHighlight,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 26),
            Text(
              strings.isPersian ? 'سرور ChatNU' : 'ChatNU server',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              strings.isPersian
                  ? 'فقط سروری را وارد کنید که به آن اعتماد دارید.'
                  : 'Only connect to a server you trust.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 22),
            TextField(
              key: const Key('auth-server-field'),
              controller: _server,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: const InputDecoration(
                hintText: 'https://api.devnu.ir/',
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              style: _blackButtonStyle(context),
              onPressed: () => Navigator.of(sheetContext).pop(),
              child: Text(strings.isPersian ? 'انجام شد' : 'Done'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthTopBar extends ConsumerWidget {
  const _AuthTopBar({
    required this.canGoBack,
    required this.onBack,
    required this.onServer,
  });

  final bool canGoBack;
  final VoidCallback onBack;
  final VoidCallback onServer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final endpoint = ref.watch(serverEndpointProvider);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 12, 8),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 44,
            height: 44,
            child: canGoBack
                ? IconButton(
                    key: const Key('auth-back'),
                    onPressed: onBack,
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 19,
                    ),
                  )
                : const Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: ChatNuMark(size: 32),
                  ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: onServer,
            icon: const Icon(Icons.lock_outline_rounded, size: 15),
            label: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                endpoint.enrollmentValue,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroTitle extends StatelessWidget {
  const _HeroTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 18),
        Text(
          title,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontSize: 34,
            height: 1.08,
            letterSpacing: -1.25,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: palette.textSecondary,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: Theme.of(
      context,
    ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
  );
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.obscure,
    required this.enabled,
    required this.onToggleVisibility,
    required this.onSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final bool obscure;
  final bool enabled;
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
        hintText: '••••••••••',
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
        return Expanded(
          child: Container(
            height: 3,
            margin: EdgeInsetsDirectional.only(end: index == count - 1 ? 0 : 5),
            decoration: BoxDecoration(
              color: index <= step ? palette.textPrimary : palette.borderSubtle,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        );
      }),
    );
  }
}

class _ProfileReview extends StatelessWidget {
  const _ProfileReview({required this.displayName, required this.username});

  final String displayName;
  final String username;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    final initial = displayName.trim().isEmpty
        ? '?'
        : displayName.trim().characters.first.toUpperCase();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.glassWeak,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 28,
            backgroundColor: palette.accentPrimary,
            foregroundColor: Colors.black,
            child: Text(
              initial,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.black),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  displayName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  '@$username',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityNote extends StatelessWidget {
  const _SecurityNote({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: palette.accentPrimary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.lock_outline_rounded,
            size: 18,
            color: Colors.black,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(body, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: palette.borderSubtle),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: <Widget>[
            const Icon(Icons.dns_outlined, size: 19),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                endpoint.enrollmentValue,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20),
          ],
        ),
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
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Text(
          message!,
          key: const Key('auth-error'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: context.chatNu.destructive,
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
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 12, 24, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FilledButton(
            key: const Key('auth-submit-button'),
            style: _blackButtonStyle(context),
            onPressed: onPrimary,
            child: busy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
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

ButtonStyle _blackButtonStyle(BuildContext context) {
  final palette = context.chatNu;
  return FilledButton.styleFrom(
    minimumSize: const Size.fromHeight(54),
    backgroundColor: palette.textPrimary,
    foregroundColor: palette.backgroundElevated,
    disabledBackgroundColor: palette.borderHighlight,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  );
}

ButtonStyle _outlineButtonStyle(BuildContext context) {
  final palette = context.chatNu;
  return OutlinedButton.styleFrom(
    minimumSize: const Size.fromHeight(54),
    foregroundColor: palette.textPrimary,
    side: BorderSide(color: palette.borderHighlight),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  );
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
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: ChatNuMark(size: 34),
                  ),
                  const Spacer(flex: 2),
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: palette.accentPrimary,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.key_rounded, color: Colors.black),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    strings.isPersian
                        ? 'کد بازیابی را ذخیره کنید'
                        : 'Save your recovery code',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontSize: 36,
                      height: 1.08,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    strings.isPersian
                        ? 'این تنها راه بازیابی حساب است. آن را خارج از ChatNU در جای امنی نگه دارید.'
                        : 'This is your account recovery key. Keep it somewhere safe outside ChatNU.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: palette.glassWeak,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: SelectableText(
                            recoveryCode,
                            key: const Key('recovery-code-result'),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          tooltip: strings.copy,
                          onPressed: () => unawaited(
                            Clipboard.setData(
                              ClipboardData(text: recoveryCode),
                            ),
                          ),
                          icon: const Icon(Icons.copy_rounded),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 3),
                  FilledButton(
                    key: const Key('recovery-code-acknowledge'),
                    style: _blackButtonStyle(context),
                    onPressed: onContinue,
                    child: Text(
                      strings.isPersian ? 'ذخیره کردم' : 'I saved it',
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
}
