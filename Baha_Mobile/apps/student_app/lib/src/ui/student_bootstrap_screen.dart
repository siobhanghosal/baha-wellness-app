import 'package:baha_shared_models/baha_shared_models.dart';
import 'package:flutter/material.dart';

class StudentBootstrapScreen extends StatefulWidget {
  const StudentBootstrapScreen({
    required this.initialEmail,
    required this.externalAuthId,
    required this.onSubmit,
    required this.onChangeIdentity,
    super.key,
  });

  final String? initialEmail;
  final String externalAuthId;
  final Future<void> Function(StudentBootstrapRequest request) onSubmit;
  final Future<void> Function() onChangeIdentity;

  @override
  State<StudentBootstrapScreen> createState() => _StudentBootstrapScreenState();
}

class _StudentBootstrapScreenState extends State<StudentBootstrapScreen> {
  final _displayNameController = TextEditingController();
  final _schoolNameController = TextEditingController(text: 'BAHA Pilot School');
  late final TextEditingController _emailController;
  String _ageCohort = '13_14';
  String _legalConsentBand = 'minor';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _schoolNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await widget.onSubmit(
        StudentBootstrapRequest(
          displayName: _displayNameController.text.trim(),
          schoolName: _schoolNameController.text.trim(),
          ageCohort: _ageCohort,
          legalConsentBand: _legalConsentBand,
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
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
              const SizedBox(height: 16),
              Text('Finish student setup', style: theme.headlineMedium),
              const SizedBox(height: 10),
              Text(
                'The backend returned `bootstrap`, so this identity does not yet have a BAHA student profile.',
                style: theme.bodyLarge,
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Development identity', style: theme.titleLarge),
                      const SizedBox(height: 8),
                      Text(widget.externalAuthId, style: theme.bodyLarge),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _displayNameController,
                        decoration: const InputDecoration(labelText: 'Display name'),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _schoolNameController,
                        decoration: const InputDecoration(labelText: 'School name'),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email (optional)',
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _ageCohort,
                        items: const [
                          DropdownMenuItem(value: '9_12', child: Text('Age 9-12')),
                          DropdownMenuItem(value: '13_14', child: Text('Age 13-14')),
                          DropdownMenuItem(value: '15_18', child: Text('Age 15-18')),
                          DropdownMenuItem(value: '18_plus', child: Text('Age 18+')),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            _ageCohort = value;
                            _legalConsentBand = value == '18_plus' ? 'adult' : 'minor';
                          });
                        },
                        decoration: const InputDecoration(labelText: 'Age cohort'),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _legalConsentBand,
                        items: const [
                          DropdownMenuItem(value: 'minor', child: Text('Minor flow')),
                          DropdownMenuItem(value: 'adult', child: Text('Adult self-consent flow')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _legalConsentBand = value);
                          }
                        },
                        decoration: const InputDecoration(labelText: 'Consent band'),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        child: Text(_submitting ? 'Submitting...' : 'Create student profile'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: widget.onChangeIdentity,
                child: const Text('Switch development identity'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
