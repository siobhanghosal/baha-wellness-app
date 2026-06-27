import 'package:baha_shared_models/baha_shared_models.dart';
import 'package:flutter/material.dart';

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
    _externalAuthIdController = TextEditingController(text: widget.defaultExternalAuthId);
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
          authEmail: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
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
    final theme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text('Student app bootstrap', style: theme.headlineMedium),
              const SizedBox(height: 12),
              Text(
                'This build uses the backend development identity bridge until hosted auth is provisioned.',
                style: theme.bodyLarge,
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('API target', style: theme.titleLarge),
                      const SizedBox(height: 8),
                      Text(widget.apiBaseUrl, style: theme.bodyLarge),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _externalAuthIdController,
                        decoration: const InputDecoration(
                          labelText: 'External auth ID',
                          hintText: 'supabase-student-demo',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Auth email (optional)',
                          hintText: 'student.demo@baha.local',
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        child: Text(_submitting ? 'Connecting...' : 'Continue'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Use a seeded ID like `supabase-student-demo` to land on the seeded demo student immediately, or enter a new ID to test the bootstrap path.',
                style: theme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
