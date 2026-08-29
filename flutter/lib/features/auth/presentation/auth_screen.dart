import 'package:chatnu/core/di/app_providers.dart';
import 'package:chatnu/core/glass/glass_components.dart';
import 'package:chatnu/core/glass/glass_surface.dart';
import 'package:chatnu/core/localization/chatnu_strings.dart';
import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:chatnu/core/theme/chatnu_tokens.dart';
import 'package:chatnu/features/auth/application/session_controller.dart';
import 'package:chatnu/shared/widgets/chatnu_mark.dart';
import 'package:flutter/material.dart';
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
    final palette = context.chatNu;
    final strings = ChatNuStrings.of(context);
    final endpoint = ref.watch(serverEndpointProvider);
    final session = ref.watch(sessionProvider);
    if (_server.text == 'https://api.devnu.ir/' &&
        endpoint.enrollmentValue != _server.text) {
      _server.text = endpoint.enrollmentValue;
    }

    return GlassScaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(ChatNuSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: GlassSurface(
                variant: GlassVariant.strong,
                enableBlur: true,
                borderRadius: ChatNuRadii.xl,
                padding: const EdgeInsets.all(ChatNuSpacing.xl),
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const ChatNuMark(size: 50),
                          const SizedBox(width: ChatNuSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  strings.appName,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                Text(
                                  strings.secureMessaging,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: ChatNuSpacing.lg),
                      Text(
                        _title(strings.isPersian),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: ChatNuSpacing.xs),
                      Text(
                        _subtitle(strings.isPersian),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: ChatNuSpacing.lg),
                      GlassSegmentedControl<AuthMode>(
                        value: _mode,
                        onChanged: _busy
                            ? (_) {}
                            : (value) {
                                setState(() {
                                  _mode = value;
                                  _error = null;
                                });
                              },
                        items: <AuthMode, String>{
                          AuthMode.login: strings.login,
                          AuthMode.register: strings.register,
                          AuthMode.recover: strings.isPersian
                              ? 'بازیابی'
                              : 'Recover',
                        },
                      ),
                      const SizedBox(height: ChatNuSpacing.md),
                      TextField(
                        key: const Key('auth-server-field'),
                        controller: _server,
                        keyboardType: TextInputType.url,
                        autocorrect: false,
                        enabled: !_busy,
                        decoration: InputDecoration(
                          labelText: strings.server,
                          hintText: 'https://api.devnu.ir/',
                          prefixIcon: const Icon(Icons.dns_outlined),
                        ),
                      ),
                      const SizedBox(height: ChatNuSpacing.sm),
                      TextField(
                        key: const Key('auth-username-field'),
                        controller: _username,
                        autocorrect: false,
                        enabled: !_busy,
                        textCapitalization: TextCapitalization.none,
                        autofillHints: const <String>[AutofillHints.username],
                        decoration: InputDecoration(
                          labelText: strings.isPersian
                              ? 'نام کاربری'
                              : 'Username',
                          prefixIcon: const Icon(Icons.alternate_email_rounded),
                        ),
                      ),
                      if (_mode == AuthMode.register) ...<Widget>[
                        const SizedBox(height: ChatNuSpacing.sm),
                        TextField(
                          key: const Key('auth-display-name-field'),
                          controller: _displayName,
                          enabled: !_busy,
                          autofillHints: const <String>[AutofillHints.name],
                          decoration: InputDecoration(
                            labelText: strings.isPersian
                                ? 'نام نمایشی'
                                : 'Display name',
                            prefixIcon: const Icon(Icons.badge_outlined),
                          ),
                        ),
                      ],
                      if (_mode == AuthMode.recover) ...<Widget>[
                        const SizedBox(height: ChatNuSpacing.sm),
                        TextField(
                          key: const Key('auth-recovery-code-field'),
                          controller: _recoveryCode,
                          enabled: !_busy,
                          autocorrect: false,
                          decoration: InputDecoration(
                            labelText: strings.isPersian
                                ? 'کد بازیابی'
                                : 'Recovery code',
                            prefixIcon: const Icon(Icons.key_outlined),
                          ),
                        ),
                      ],
                      const SizedBox(height: ChatNuSpacing.sm),
                      TextField(
                        key: const Key('auth-password-field'),
                        controller: _password,
                        enabled: !_busy,
                        obscureText: _obscurePassword,
                        enableSuggestions: false,
                        autocorrect: false,
                        autofillHints: <String>[
                          _mode == AuthMode.login
                              ? AutofillHints.password
                              : AutofillHints.newPassword,
                        ],
                        onSubmitted: (_) {
                          if (!_busy) _submit();
                        },
                        decoration: InputDecoration(
                          labelText: _mode == AuthMode.recover
                              ? (strings.isPersian
                                    ? 'گذرواژهٔ جدید'
                                    : 'New password')
                              : (strings.isPersian ? 'گذرواژه' : 'Password'),
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? (strings.isPersian
                                      ? 'نمایش گذرواژه'
                                      : 'Show password')
                                : (strings.isPersian
                                      ? 'پنهان کردن گذرواژه'
                                      : 'Hide password'),
                            onPressed: _busy
                                ? null
                                : () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                      ),
                      if (_error != null) ...<Widget>[
                        const SizedBox(height: ChatNuSpacing.sm),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _error!,
                            key: const Key('auth-error'),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: palette.destructive),
                          ),
                        ),
                      ],
                      const SizedBox(height: ChatNuSpacing.md),
                      GlassButton(
                        key: const Key('auth-submit-button'),
                        label: _submitLabel(strings.isPersian),
                        icon: _submitIcon,
                        prominent: true,
                        onPressed: _busy ? null : _submit,
                      ),
                      if (_busy) ...<Widget>[
                        const SizedBox(height: ChatNuSpacing.sm),
                        const LinearProgressIndicator(minHeight: 2),
                      ],
                      if (session.recoveryCode != null) ...<Widget>[
                        const SizedBox(height: ChatNuSpacing.md),
                        Container(
                          padding: const EdgeInsets.all(ChatNuSpacing.sm),
                          decoration: BoxDecoration(
                            color: palette.warning.withValues(alpha: 0.09),
                            borderRadius: BorderRadius.circular(ChatNuRadii.md),
                            border: Border.all(
                              color: palette.warning.withValues(alpha: 0.22),
                            ),
                          ),
                          child: SelectableText(
                            strings.isPersian
                                ? 'این کد بازیابی را اکنون ذخیره کنید: ${session.recoveryCode}'
                                : 'Save this recovery code now: ${session.recoveryCode}',
                            key: const Key('recovery-code-result'),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                      const SizedBox(height: ChatNuSpacing.md),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Icon(
                            endpoint.usesEmergencyTls
                                ? Icons.warning_amber_rounded
                                : Icons.lock_outline_rounded,
                            size: 18,
                            color: endpoint.usesEmergencyTls
                                ? palette.warning
                                : palette.success,
                          ),
                          const SizedBox(width: ChatNuSpacing.xs),
                          Expanded(
                            child: Text(
                              endpoint.usesEmergencyTls
                                  ? (strings.isPersian
                                        ? 'ثبت CA اضطراری ذخیره شده است، اما Flutter تا رسیدن بررسی pin بومی به برابری با Android، این انتقال را رد می‌کند.'
                                        : 'Emergency CA enrollment is saved, but Flutter refuses this transport until native CA-pin verification reaches Android parity.')
                                  : (strings.isPersian
                                        ? 'کلید خصوصی هویت E2EE روی همین دستگاه باقی می‌ماند. نشانی سرور بالا مرز اعتماد اتصال شماست.'
                                        : 'The private E2EE identity key stays on this device. The server address above is the trust boundary for your connection.'),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(serverEndpointProvider.notifier).configure(_server.text);
      final controller = ref.read(sessionProvider.notifier);
      final error = switch (_mode) {
        AuthMode.login => await controller.login(
          username: _username.text,
          password: _password.text,
        ),
        AuthMode.register => await controller.register(
          username: _username.text,
          password: _password.text,
          displayName: _displayName.text,
        ),
        AuthMode.recover => await controller.recover(
          username: _username.text,
          recoveryCode: _recoveryCode.text,
          newPassword: _password.text,
        ),
      };
      if (mounted) setState(() => _error = error);
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _title(bool fa) => switch (_mode) {
    AuthMode.login => fa ? 'خوش برگشتید' : 'Welcome back',
    AuthMode.register =>
      fa ? 'حساب ChatNU بسازید' : 'Create your ChatNU account',
    AuthMode.recover => fa ? 'بازیابی حساب' : 'Recover your account',
  };

  String _subtitle(bool fa) => switch (_mode) {
    AuthMode.login =>
      fa
          ? 'برای ادامه به گفت‌وگوهای رمزگذاری‌شده وارد شوید.'
          : 'Sign in to continue to your encrypted conversations.',
    AuthMode.register =>
      fa
          ? 'پیش از ثبت‌نام، کلید هویت دستگاه به‌صورت محلی ساخته می‌شود.'
          : 'A device identity key is created locally before registration.',
    AuthMode.recover =>
      fa
          ? 'بازیابی گذرواژه را تغییر می‌دهد و دستگاه‌های موجود را لغو می‌کند.'
          : 'Recovery changes the password and revokes existing devices.',
  };

  String _submitLabel(bool fa) => switch (_mode) {
    AuthMode.login => fa ? 'ورود' : 'Login',
    AuthMode.register => fa ? 'ثبت‌نام' : 'Register',
    AuthMode.recover => fa ? 'بازیابی حساب' : 'Recover account',
  };

  IconData get _submitIcon => switch (_mode) {
    AuthMode.login => Icons.login_rounded,
    AuthMode.register => Icons.person_add_alt_1_rounded,
    AuthMode.recover => Icons.restore_rounded,
  };
}
