import 'package:baha_shared_models/baha_shared_models.dart';
import 'package:flutter/material.dart';

import '../prototype/app_theme.dart';
import '../prototype/prototype_models.dart';
import '../prototype/prototype_widgets.dart';

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
  final Future<void> Function(DevelopmentIdentity identity) onSubmit;

  @override
  State<StudentIdentityScreen> createState() => _StudentIdentityScreenState();
}

class _StudentIdentityScreenState extends State<StudentIdentityScreen> {
  late final TextEditingController _externalAuthIdController;
  late final TextEditingController _emailController;
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
    setState(() => _submitting = true);
    try {
      await widget.onSubmit(
        DevelopmentIdentity(
          externalAuthId: _externalAuthIdController.text.trim(),
          authEmail: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = studentPalette(StudentAgeGroup.teen, StudentGender.female);
    return Theme(
      data: buildTheme(palette),
      child: AnimatedGradientScaffold(
        palette: palette,
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            HeroHeader(
              palette: palette,
              kicker: AppRole.student.label,
              title: 'Welcome back',
              subtitle:
                  'Connect the real student app using the development identity bridge until hosted auth is provisioned.',
              actions: const [
                Pill(icon: Icons.lock_open_rounded, label: 'Dev auth'),
                Pill(icon: Icons.cloud_done_rounded, label: 'Real backend'),
              ],
            ),
            const SizedBox(height: 22),
            GlassPanel(
              palette: palette,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Connect to BAHA Student',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Use the seeded student identity for the fastest path into the live backend.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _externalAuthIdController,
                    decoration: const InputDecoration(
                      labelText: 'External auth ID',
                      hintText: 'supabase-student-demo',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Auth email (optional)',
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
                    label: _submitting ? 'Connecting...' : 'Enter Student App',
                    icon: Icons.login_rounded,
                    onPressed: _submitting ? () {} : _submit,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassPanel(
              palette: palette,
              child: Text(
                'Use `supabase-student-demo` for the seeded student, or enter a new external ID to test the bootstrap path.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
