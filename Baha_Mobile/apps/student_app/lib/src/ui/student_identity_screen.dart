import 'package:baha_shared_models/baha_shared_models.dart';
import 'package:flutter/material.dart';

import '../prototype/app_theme.dart';
import '../prototype/prototype_widgets.dart';

enum AppEntryMode { signIn, register }

class StudentIdentityScreen extends StatefulWidget {
  const StudentIdentityScreen({
    required this.defaultExternalAuthId,
    required this.defaultAuthEmail,
    required this.apiBaseUrl,
    required this.onSubmit,
    super.key,
  });

  final String defaultExternalAuthId;
  final String defaultAuthEmail;
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
  late final TextEditingController _emailController;
  AppRequestedRole _requestedRole = AppRequestedRole.student;
  AppEntryMode _mode = AppEntryMode.signIn;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _externalAuthIdController = TextEditingController(
      text: widget.defaultExternalAuthId,
    );
    _emailController = TextEditingController(text: widget.defaultAuthEmail);
  }

  @override
  void dispose() {
    _externalAuthIdController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final externalAuthId = _externalAuthIdController.text.trim();
    final email = _emailController.text.trim();
    if (externalAuthId.isEmpty) {
      await _showDialogMessage(
        title: 'Enter your sign-in ID',
        message: 'Add a sign-in ID before continuing.',
      );
      return;
    }
    if (_mode == AppEntryMode.register && email.isEmpty) {
      await _showDialogMessage(
        title: 'Email required',
        message: 'Add an email address to create a new account.',
      );
      return;
    }
    if (_mode == AppEntryMode.register &&
        email.isNotEmpty &&
        !_looksLikeEmail(email)) {
      await _showDialogMessage(
        title: 'Enter a valid email',
        message: 'Use a valid email address before creating a new account.',
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
    if (_mode == AppEntryMode.register &&
        widget.defaultAuthEmail.isNotEmpty &&
        email.isNotEmpty &&
        email == widget.defaultAuthEmail) {
      await _showDialogMessage(
        title: 'Choose a different email',
        message:
            'The seeded demo email is only for sign-in. Use a different email to create a fresh account.',
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final errorMessage = await widget.onSubmit(
        DevelopmentIdentity(
          externalAuthId: externalAuthId,
          authEmail: email.isEmpty ? null : email,
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

  bool _looksLikeEmail(String value) {
    final trimmed = value.trim();
    return trimmed.contains('@') && trimmed.contains('.');
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
                Pill(icon: Icons.lock_open_rounded, label: 'Dev auth'),
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
                          if (_emailController.text.trim() ==
                              widget.defaultAuthEmail) {
                            _emailController.clear();
                          }
                        } else {
                          if (_externalAuthIdController.text.trim().isEmpty &&
                              widget.defaultExternalAuthId.isNotEmpty) {
                            _externalAuthIdController.text =
                                widget.defaultExternalAuthId;
                          }
                          if (_emailController.text.trim().isEmpty &&
                              widget.defaultAuthEmail.isNotEmpty) {
                            _emailController.text = widget.defaultAuthEmail;
                          }
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _externalAuthIdController,
                    decoration: const InputDecoration(
                      labelText: 'Sign-in ID',
                      hintText: 'supabase-student-demo',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'student.demo@baha.local',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'API target: ${widget.apiBaseUrl}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 18),
                  AnimatedPrimaryButton(
                    label: _submitting
                        ? 'Connecting...'
                        : _mode == AppEntryMode.signIn
                        ? 'Continue to sign in'
                        : 'Continue to register',
                    icon: _mode == AppEntryMode.signIn
                        ? Icons.arrow_forward_rounded
                        : Icons.person_add_alt_1_rounded,
                    onPressed: _submitting ? () {} : _submit,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            GlassPanel(
              palette: palette,
              child: Text(
                'This demo still uses a development identity bridge under the hood, but the app now validates sign-in versus registration separately so existing emails, reused sign-in IDs, and missing accounts are handled more like a production flow.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
