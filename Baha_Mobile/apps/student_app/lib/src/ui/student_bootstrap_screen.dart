import 'package:baha_shared_models/baha_shared_models.dart';
import 'package:flutter/material.dart';

import '../prototype/app_theme.dart';
import '../prototype/prototype_widgets.dart';
import '../wellbeing/student_profile_logic.dart';
import 'student_profile_setup_screen.dart';

class StudentBootstrapScreen extends StatefulWidget {
  const StudentBootstrapScreen({
    required this.identity,
    this.errorMessage,
    required this.onSubmit,
    required this.onChangeIdentity,
    super.key,
  });

  final DevelopmentIdentity identity;
  final String? errorMessage;
  final Future<void> Function(AppBootstrapRequest request) onSubmit;
  final Future<void> Function() onChangeIdentity;

  @override
  State<StudentBootstrapScreen> createState() => _StudentBootstrapScreenState();
}

class _StudentBootstrapScreenState extends State<StudentBootstrapScreen> {
  final _displayNameController = TextEditingController();
  final _schoolNameController = TextEditingController(
    text: 'BAHA Pilot School',
  );
  late final TextEditingController _emailController;
  final _staffCodeController = TextEditingController();

  String _ageCohort = '13_14';
  String _legalConsentBand = 'minor';
  String _guardianType = 'parent';
  String _gender = 'prefer_not_to_say';
  bool _submitting = false;
  StudentWellbeingProfile? _profile;

  AppRequestedRole get _role => widget.identity.requestedRole;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
      text: widget.identity.authEmail ?? '',
    );
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _schoolNameController.dispose();
    _emailController.dispose();
    _staffCodeController.dispose();
    super.dispose();
  }

  Future<void> _openStudentProfile() async {
    final palette = appPaletteForTheme(AppColorTheme.growth);
    final result = await Navigator.of(context).push<StudentWellbeingProfile>(
      MaterialPageRoute<StudentWellbeingProfile>(
        builder: (context) => StudentProfileSetupScreen(
          palette: palette,
          initialProfile: _profile,
          title: 'Set up your baseline',
          subtitle:
              'This one-time onboarding is part of account creation. It should be short, private, and useful enough to personalize future daily check-ins.',
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _profile = result;
        _ageCohort = result.ageBand;
        _legalConsentBand = result.ageBand == '18_plus' ? 'adult' : 'minor';
        if (result.genderIdentity == 'male' ||
            result.genderIdentity == 'female') {
          _gender = result.genderIdentity;
        }
      });
    }
  }

  Future<void> _submit() async {
    final displayName = _displayNameController.text.trim();
    final schoolName = _schoolNameController.text.trim();
    final email = _emailController.text.trim();
    final staffCode = _staffCodeController.text.trim();

    if (displayName.length < 2) {
      _showValidationError('Enter a display name with at least 2 characters.');
      return;
    }
    if (_requiresSchool && schoolName.length < 2) {
      _showValidationError(
        'Enter a valid school name before creating the account.',
      );
      return;
    }
    if (_requiresStaffCode && staffCode.length < 2) {
      _showValidationError(
        'Enter a valid staff code before creating the account.',
      );
      return;
    }
    if (_role == AppRequestedRole.student && _profile == null) {
      _showValidationError(
        'Finish the one-time onboarding profile before creating a student account.',
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await widget.onSubmit(
        AppBootstrapRequest(
          role: _role,
          displayName: displayName,
          email: email.isEmpty ? null : email,
          schoolName: _requiresSchool ? schoolName : null,
          ageCohort: _role == AppRequestedRole.student ? _ageCohort : null,
          legalConsentBand: _role == AppRequestedRole.student
              ? _legalConsentBand
              : null,
          gender: _role == AppRequestedRole.student ? _gender : 'unspecified',
          guardianType: _guardianType,
          staffCode: _requiresStaffCode ? staffCode : null,
          metadata: _role == AppRequestedRole.student
              ? _profile!.toBootstrapMetadata()
              : const {},
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  bool get _requiresSchool =>
      _role == AppRequestedRole.student || _role == AppRequestedRole.teacher;

  bool get _requiresStaffCode =>
      _role == AppRequestedRole.teacher || _role == AppRequestedRole.counselor;

  void _showValidationError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
              kicker: 'Register',
              title: 'Create your ${_role.label.toLowerCase()} account',
              subtitle: _role == AppRequestedRole.student
                  ? 'Student registration includes the one-time wellbeing baseline so daily check-ins stay short later.'
                  : 'This role-specific registration flow creates the BAHA account and aligns it to the correct experience inside the unified app.',
              actions: [
                Pill(
                  icon: switch (_role) {
                    AppRequestedRole.student =>
                      Icons.sentiment_satisfied_alt_rounded,
                    AppRequestedRole.guardian => Icons.family_restroom_rounded,
                    AppRequestedRole.teacher => Icons.menu_book_rounded,
                    AppRequestedRole.counselor => Icons.support_agent_rounded,
                  },
                  label: _role.label,
                ),
                const Pill(
                  icon: Icons.verified_user_rounded,
                  label: 'Real backend',
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (widget.errorMessage != null &&
                widget.errorMessage!.trim().isNotEmpty) ...[
              GlassPanel(
                palette: palette,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Could not create this account yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(widget.errorMessage!),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],
            GlassPanel(
              palette: palette,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account basics',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Development identity: ${widget.identity.externalAuthId}',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _displayNameController,
                    decoration: const InputDecoration(
                      labelText: 'Display name',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  if (_requiresSchool) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _schoolNameController,
                      decoration: const InputDecoration(
                        labelText: 'School name',
                      ),
                    ),
                  ],
                  if (_requiresStaffCode) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _staffCodeController,
                      decoration: const InputDecoration(
                        labelText: 'Staff code',
                      ),
                    ),
                  ],
                  if (_role == AppRequestedRole.guardian) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _guardianType,
                      items: const [
                        DropdownMenuItem(
                          value: 'parent',
                          child: Text('Parent'),
                        ),
                        DropdownMenuItem(
                          value: 'guardian',
                          child: Text('Guardian'),
                        ),
                        DropdownMenuItem(
                          value: 'caregiver',
                          child: Text('Caregiver'),
                        ),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _guardianType = value);
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Relationship type',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (_role == AppRequestedRole.student) ...[
              const SizedBox(height: 18),
              GlassPanel(
                palette: palette,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle(
                      title: 'One-time onboarding',
                      subtitle:
                          'This is where age band, baseline wellbeing, and the small amount of context needed for personalization are captured.',
                    ),
                    if (_profile == null)
                      AnimatedPrimaryButton(
                        label: 'Start onboarding questions',
                        icon: Icons.playlist_add_check_rounded,
                        onPressed: _openStudentProfile,
                      )
                    else ...[
                      _ProfileSummaryRow(
                        label: 'Age cohort',
                        value: _profile!.ageBand.replaceAll('_', '-'),
                      ),
                      _ProfileSummaryRow(
                        label: 'Baseline focus',
                        value: _profile!.checkinFocusLabel,
                      ),
                      _ProfileSummaryRow(
                        label: 'Support style',
                        value: _profile!.supportPreferenceLabel,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _openStudentProfile,
                        icon: const Icon(Icons.edit_rounded),
                        label: const Text('Edit onboarding answers'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            AnimatedPrimaryButton(
              label: _submitting ? 'Creating account...' : 'Create account',
              icon: Icons.arrow_forward_rounded,
              onPressed: _submitting ? () {} : _submit,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: widget.onChangeIdentity,
              child: const Text('Back to role selection'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSummaryRow extends StatelessWidget {
  const _ProfileSummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
