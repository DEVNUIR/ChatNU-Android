import 'package:chatnu/core/di/app_providers.dart';
import 'package:chatnu/core/glass/glass_surface.dart';
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
    final endpoint = ref.watch(serverEndpointProvider);
    final session = ref.watch(sessionProvider);
    if (_server.text == 'https://api.devnu.ir/' &&
        endpoint.enrollmentValue != _server.text) {
      _server.text = endpoint.enrollmentValue;
    }

    return Scaffold(
      backgroundColor: palette.backgroundPrimary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(ChatNuSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: GlassSurface(
                variant: GlassVariant.strong,
                enableBlur: true,
                borderRadius: ChatNuRadii.xl,
                padding: const EdgeInsets.all(ChatNuSpacing.xl),
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: ChatNuMark(size: 48),
                      ),
                      const SizedBox(height: ChatNuSpacing.md),
                      Text(
                        _title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: ChatNuSpacing.xs),
                      Text(
                        _subtitle,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: ChatNuSpacing.lg),
                      SegmentedButton<AuthMode>(
                        segments: const <ButtonSegment<AuthMode>>[
                          ButtonSegment(
                            value: AuthMode.login,
                            label: Text('Login'),
                          ),
                          ButtonSegment(
                            value: AuthMode.register,
                            label: Text('Register'),
                          ),
                          ButtonSegment(
                            value: AuthMode.recover,
                            label: Text('Recover'),
                          ),
                        ],
                        selected: <AuthMode>{_mode},
                        onSelectionChanged: _busy
                            ? null
                            : (selection) {
                                setState(() {
                                  _mode = selection.first;
                                  _error = null;
                                });
                              },
                      ),
                      const SizedBox(height: ChatNuSpacing.md),
                      TextField(
                        key: const Key('auth-server-field'),
                        controller: _server,
                        keyboardType: TextInputType.url,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'Server',
                          hintText: 'https://api.devnu.ir/',
                          prefixIcon: Icon(Icons.dns_outlined),
                        ),
                      ),
                      const SizedBox(height: ChatNuSpacing.sm),
                      TextField(
                        key: const Key('auth-username-field'),
                        controller: _username,
                        autocorrect: false,
                        textCapitalization: TextCapitalization.none,
                        autofillHints: const <String>[AutofillHints.username],
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.alternate_email_rounded),
                        ),
                      ),
                      if (_mode == AuthMode.register) ...<Widget>[
                        const SizedBox(height: ChatNuSpacing.sm),
                        TextField(
                          key: const Key('auth-display-name-field'),
                          controller: _displayName,
                          autofillHints: const <String>[AutofillHints.name],
                          decoration: const InputDecoration(
                            labelText: 'Display name',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                        ),
                      ],
                      if (_mode == AuthMode.recover) ...<Widget>[
                        const SizedBox(height: ChatNuSpacing.sm),
                        TextField(
                          key: const Key('auth-recovery-code-field'),
                          controller: _recoveryCode,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: 'Recovery code',
                            prefixIcon: Icon(Icons.key_outlined),
                          ),
                        ),
                      ],
                      const SizedBox(height: ChatNuSpacing.sm),
                      TextField(
                        key: const Key('auth-password-field'),
                        controller: _password,
                        obscureText: _obscurePassword,
                        enableSuggestions: false,
                        autocorrect: false,
                        autofillHints: <String>[
                          _mode == AuthMode.login
                              ? AutofillHints.password
                              : AutofillHints.newPassword,
                        ],
                        onSubmitted: (_) => _busy ? null : _submit(),
                        decoration: InputDecoration(
                          labelText: _mode == AuthMode.recover
                              ? 'New password'
                              : 'Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? 'Show password'
                                : 'Hide password',
                            onPressed: () => setState(
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
                        Text(
                          _error!,
                          key: const Key('auth-error'),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: palette.destructive,
                          ),
                        ),
                      ],
                      const SizedBox(height: ChatNuSpacing.md),
                      FilledButton.icon(
                        key: const Key('auth-submit-button'),
                        onPressed: _busy ? null : _submit,
                        icon: _busy
                            ? const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(_submitIcon),
                        label: Text(_submitLabel),
                      ),
                      if (session.recoveryCode != null) ...<Widget>[
                        const SizedBox(height: ChatNuSpacing.md),
                        SelectableText(
                          'Save this recovery code now: ${session.recoveryCode}',
                          key: const Key('recovery-code-result'),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                      const SizedBox(height: ChatNuSpacing.sm),
                      Text(
                        endpoint.usesEmergencyTls
                            ? 'Emergency CA enrollment is saved, but Flutter refuses to bypass system TLS validation until native pinned-transport parity is enabled.'
                            : 'Passwords and private E2EE keys are never sent anywhere except through the selected ChatNU authentication protocol; private identity keys stay on this device.',
                        style: Theme.of(context).textTheme.bodySmall,
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

  String get _title => switch (_mode) {
    AuthMode.login => 'Welcome back',
    AuthMode.register => 'Create your ChatNU account',
    AuthMode.recover => 'Recover your account',
  };

  String get _subtitle => switch (_mode) {
    AuthMode.login => 'Sign in to continue to your encrypted conversations.',
    AuthMode.register => 'A device identity key is created locally before registration.',
    AuthMode.recover => 'Recovery changes the password and revokes existing devices.',
  };

  String get _submitLabel => switch (_mode) {
    AuthMode.login => 'Login',
    AuthMode.register => 'Register',
    AuthMode.recover => 'Recover account',
  };

  IconData get _submitIcon => switch (_mode) {
    AuthMode.login => Icons.login_rounded,
    AuthMode.register => Icons.person_add_alt_1_rounded,
    AuthMode.recover => Icons.restore_rounded,
  };
}
