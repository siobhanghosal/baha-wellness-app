import 'package:baha_shared_models/baha_shared_models.dart';
import 'package:flutter/material.dart';

import '../prototype/app_theme.dart';
import '../prototype/prototype_widgets.dart';

enum AppEntryMode { signIn, register }

class StudentIdentityScreen extends StatefulWidget {
  const StudentIdentityScreen({
    required this.defaultExternalAuthId,
    required this.defaultPassword,
    required this.apiBaseUrl,
    required this.onSubmit,
    super.key,
  });

  final String defaultExternalAuthId;
  final String defaultPassword;
  final String apiBaseUrl;
  final Future<String?> Function(
    DevelopmentIdentity identity,
    AppEntryMode mode,
  )
  onSubmit;

  @override
  State<StudentIdentityScreen> createState() => _StudentIdentityScreenState();
}

class _StudentIdentityScreenState extends State<StudentIdentityScreen> {
  late final TextEditingController _externalAuthIdController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  AppRequestedRole _requestedRole = AppRequestedRole.student;
  AppEntryMode _mode = AppEntryMode.signIn;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _externalAuthIdController = TextEditingController(
      text: widget.defaultExternalAuthId,
    );
    _passwordController = TextEditingController(text: widget.defaultPassword);
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _externalAuthIdController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final externalAuthId = _externalAuthIdController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    if (externalAuthId.isEmpty) {
      await _showDialogMessage(
        title: 'Enter your sign-in ID',
        message: 'Add a sign-in ID before continuing.',
      );
      return;
    }
    if (password.isEmpty) {
      await _showDialogMessage(
        title: 'Password required',
        message: 'Enter your password before continuing.',
      );
      return;
    }
    if (_mode == AppEntryMode.register && password.length < 8) {
      await _showDialogMessage(
        title: 'Choose a stronger password',
        message: 'Use at least 8 characters when creating a new account.',
      );
      return;
    }
    if (_mode == AppEntryMode.register &&
        widget.defaultExternalAuthId.isNotEmpty &&
        externalAuthId == widget.defaultExternalAuthId) {
      await _showDialogMessage(
        title: 'Choose a new sign-in ID',
        message:
            'The seeded demo sign-in ID is only for sign-in. Use a new sign-in ID to create a fresh account.',
      );
      return;
    }
    if (_mode == AppEntryMode.register && confirmPassword != password) {
      await _showDialogMessage(
        title: 'Passwords do not match',
        message:
            'Make sure both password fields match before creating the account.',
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final errorMessage = await widget.onSubmit(
        DevelopmentIdentity(
          externalAuthId: externalAuthId,
          password: password,
          requestedRole: _requestedRole,
        ),
        _mode,
      );
      if (errorMessage != null && mounted) {
        await _showDialogMessage(
          title: _mode == AppEntryMode.signIn
              ? 'Could not sign in'
              : 'Could not create account',
          message: errorMessage,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _showDialogMessage({
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = appPaletteForTheme(AppColorTheme.growth);
    return Theme(
      data: buildTheme(palette),
      child: AnimatedGradientScaffold(
        palette: palette,
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            HeroHeader(
              palette: palette,
              kicker: 'BAHA',
              title: 'One app, role-based experience',
              subtitle:
                  'Choose who the app is for first, then continue into sign-in or account creation.',
              actions: const [
                Pill(icon: Icons.apps_rounded, label: 'Unified app'),
                Pill(icon: Icons.lock_outline_rounded, label: 'Secure sign-in'),
              ],
            ),
            const SizedBox(height: 20),
            GlassPanel(
              palette: palette,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Who is this app for?',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: AppRequestedRole.values.map((role) {
                      final selected = role == _requestedRole;
                      return ChoiceChip(
                        label: Text(role.label),
                        avatar: Icon(switch (role) {
                          AppRequestedRole.student =>
                            Icons.sentiment_satisfied_alt_rounded,
                          AppRequestedRole.guardian =>
                            Icons.family_restroom_rounded,
                          AppRequestedRole.teacher => Icons.menu_book_rounded,
                          AppRequestedRole.counselor =>
                            Icons.support_agent_rounded,
                        }, size: 18),
                        selected: selected,
                        selectedColor: palette.primary.withValues(alpha: .18),
                        onSelected: (_) {
                          setState(() => _requestedRole = role);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SegmentedButton<AppEntryMode>(
                    segments: const [
                      ButtonSegment(
                        value: AppEntryMode.signIn,
                        label: Text('Sign in'),
                        icon: Icon(Icons.login_rounded),
                      ),
                      ButtonSegment(
                        value: AppEntryMode.register,
                        label: Text('Register'),
                        icon: Icon(Icons.person_add_alt_1_rounded),
                      ),
                    ],
                    selected: <AppEntryMode>{_mode},
                    onSelectionChanged: (selection) {
                      final nextMode = selection.first;
                      setState(() {
                        _mode = nextMode;
                        if (nextMode == AppEntryMode.register) {
                          if (_externalAuthIdController.text.trim() ==
                              widget.defaultExternalAuthId) {
                            _externalAuthIdController.clear();
                          }
                          if (_passwordController.text.trim() ==
                              widget.defaultPassword) {
                            _passwordController.clear();
                          }
                          _confirmPasswordController.clear();
                        } else {
                          if (_externalAuthIdController.text.trim().isEmpty &&
                              widget.defaultExternalAuthId.isNotEmpty) {
                            _externalAuthIdController.text =
                                widget.defaultExternalAuthId;
                          }
                          if (_passwordController.text.trim().isEmpty &&
                              widget.defaultPassword.isNotEmpty) {
                            _passwordController.text = widget.defaultPassword;
                          }
                          _confirmPasswordController.clear();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _externalAuthIdController,
                    decoration: const InputDecoration(
                      labelText: 'Sign-in ID',
                      hintText: 'Enter your sign-in ID',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: _mode == AppEntryMode.signIn
                          ? 'Enter your password'
                          : 'Create a password',
                    ),
                  ),
                  if (_mode == AppEntryMode.register) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirm password',
                        hintText: 'Re-enter your password',
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  AnimatedPrimaryButton(
                    label: _submitting
                        ? 'Connecting...'
                        : _mode == AppEntryMode.signIn
                        ? 'Sign in'
                        : 'Create account',
                    icon: _mode == AppEntryMode.signIn
                        ? Icons.arrow_forward_rounded
                        : Icons.person_add_alt_1_rounded,
                    onPressed: _submitting ? () {} : _submit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
