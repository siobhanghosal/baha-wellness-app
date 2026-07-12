import 'package:flutter/material.dart';

import '../prototype/app_theme.dart';
import '../prototype/prototype_widgets.dart';
import '../wellbeing/student_profile_logic.dart';

class StudentProfileSetupScreen extends StatefulWidget {
  const StudentProfileSetupScreen({
    required this.palette,
    this.initialProfile,
    this.title = 'Your wellbeing profile',
    this.subtitle =
        'Answer this once so BAHA can keep daily check-ins short and personalize follow-up questions responsibly.',
    super.key,
  });

  final PrototypePalette palette;
  final StudentWellbeingProfile? initialProfile;
  final String title;
  final String subtitle;

  @override
  State<StudentProfileSetupScreen> createState() =>
      _StudentProfileSetupScreenState();
}

class _StudentProfileSetupScreenState extends State<StudentProfileSetupScreen> {
  late String _ageBand;
  late String _genderIdentity;
  late String _trustedSupportPerson;
  late String _schoolDaySleepQuality;
  late String _usualEnergy;
  late String _weeklyStressFrequency;
  late String _mainPressure;
  late String _mainPhysicalIssue;
  late String _experiencesPeriods;
  String? _periodImpact;
  late String _copingStyle;
  late String _helpSeekingEase;
  late String _socialConnectedness;
  late String _supportPreference;
  late String _checkinFocus;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialProfile;
    _ageBand = initial?.ageBand ?? '13_14';
    _genderIdentity = initial?.genderIdentity ?? 'prefer_not_to_say';
    _trustedSupportPerson = initial?.trustedSupportPerson ?? 'parent_guardian';
    _schoolDaySleepQuality = initial?.schoolDaySleepQuality ?? 'okay';
    _usualEnergy = initial?.usualEnergy ?? 'okay';
    _weeklyStressFrequency = initial?.weeklyStressFrequency ?? 'sometimes';
    _mainPressure = initial?.mainPressure ?? 'school';
    _mainPhysicalIssue = initial?.mainPhysicalIssue ?? 'none';
    _experiencesPeriods = initial?.experiencesPeriods ?? 'prefer_not_to_say';
    _periodImpact = initial?.periodImpact;
    _copingStyle = initial?.copingStyle ?? 'talk_to_someone';
    _helpSeekingEase = initial?.helpSeekingEase ?? 'mixed';
    _socialConnectedness = initial?.socialConnectedness ?? 'mostly_connected';
    _supportPreference = initial?.supportPreference ?? 'quick_tips';
    _checkinFocus = initial?.checkinFocus ?? 'no_preference';
  }

  void _save() {
    if (_experiencesPeriods == 'yes' &&
        (_periodImpact == null || _periodImpact!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Choose how much periods affect energy, pain, or mood.',
          ),
        ),
      );
      return;
    }
    Navigator.of(context).pop(
      StudentWellbeingProfile(
        ageBand: _ageBand,
        genderIdentity: _genderIdentity,
        trustedSupportPerson: _trustedSupportPerson,
        schoolDaySleepQuality: _schoolDaySleepQuality,
        usualEnergy: _usualEnergy,
        weeklyStressFrequency: _weeklyStressFrequency,
        mainPressure: _mainPressure,
        mainPhysicalIssue: _mainPhysicalIssue,
        experiencesPeriods: _experiencesPeriods,
        periodImpact: _experiencesPeriods == 'yes' ? _periodImpact : null,
        copingStyle: _copingStyle,
        helpSeekingEase: _helpSeekingEase,
        socialConnectedness: _socialConnectedness,
        supportPreference: _supportPreference,
        checkinFocus: _checkinFocus,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    return Theme(
      data: buildTheme(palette),
      child: AnimatedGradientScaffold(
        palette: palette,
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const Spacer(),
                ThemeModeToggle(palette: palette),
              ],
            ),
            HeroHeader(
              palette: palette,
              kicker: 'One-time onboarding',
              title: widget.title,
              subtitle: widget.subtitle,
              actions: const [
                Pill(icon: Icons.psychology_alt_rounded, label: 'Profile-led'),
                Pill(icon: Icons.lock_rounded, label: 'Private'),
              ],
            ),
            const SizedBox(height: 18),
            _ChoiceSection(
              palette: palette,
              title: 'Identity and support',
              subtitle: 'Context that changes how the app interprets trends.',
              children: [
                _ChoiceField(
                  palette: palette,
                  question: 'Age band',
                  value: _ageBand,
                  options: const <String, String>{
                    '9_12': '9-12',
                    '13_14': '13-14',
                    '15_18': '15-18',
                    '18_plus': '18+',
                  },
                  onChanged: (value) => setState(() => _ageBand = value),
                ),
                _ChoiceField(
                  palette: palette,
                  question: 'Gender identity',
                  value: _genderIdentity,
                  options: genderIdentityOptions,
                  onChanged: (value) => setState(() => _genderIdentity = value),
                ),
                _ChoiceField(
                  palette: palette,
                  question:
                      'Who do you usually talk to when something feels wrong?',
                  value: _trustedSupportPerson,
                  options: trustedSupportOptions,
                  onChanged: (value) =>
                      setState(() => _trustedSupportPerson = value),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _ChoiceSection(
              palette: palette,
              title: 'Baseline wellbeing',
              subtitle: 'This becomes the reference point for daily check-ins.',
              children: [
                _ChoiceField(
                  palette: palette,
                  question: 'How is your sleep usually on school days?',
                  value: _schoolDaySleepQuality,
                  options: baselineScaleOptions,
                  onChanged: (value) =>
                      setState(() => _schoolDaySleepQuality = value),
                ),
                _ChoiceField(
                  palette: palette,
                  question: 'How would you describe your usual energy?',
                  value: _usualEnergy,
                  options: baselineScaleOptions,
                  onChanged: (value) => setState(() => _usualEnergy = value),
                ),
                _ChoiceField(
                  palette: palette,
                  question: 'How often do you feel stressed in a normal week?',
                  value: _weeklyStressFrequency,
                  options: stressFrequencyOptions,
                  onChanged: (value) =>
                      setState(() => _weeklyStressFrequency = value),
                ),
                _ChoiceField(
                  palette: palette,
                  question: 'What usually affects you the most?',
                  value: _mainPressure,
                  options: mainPressureOptions,
                  onChanged: (value) => setState(() => _mainPressure = value),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _ChoiceSection(
              palette: palette,
              title: 'Physical context',
              subtitle:
                  'Only ask what changes interpretation meaningfully later on.',
              children: [
                _ChoiceField(
                  palette: palette,
                  question: 'What physical issue shows up most often?',
                  value: _mainPhysicalIssue,
                  options: physicalIssueOptions,
                  onChanged: (value) =>
                      setState(() => _mainPhysicalIssue = value),
                ),
                _ChoiceField(
                  palette: palette,
                  question: 'Do you experience periods?',
                  value: _experiencesPeriods,
                  options: yesNoUnknownOptions,
                  onChanged: (value) {
                    setState(() {
                      _experiencesPeriods = value;
                      if (value != 'yes') {
                        _periodImpact = null;
                      }
                    });
                  },
                ),
                if (_experiencesPeriods == 'yes')
                  _ChoiceField(
                    palette: palette,
                    question:
                        'Do periods sometimes affect energy, pain, or mood?',
                    value: _periodImpact,
                    options: periodImpactOptions,
                    onChanged: (value) => setState(() => _periodImpact = value),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            _ChoiceSection(
              palette: palette,
              title: 'Social and coping style',
              subtitle:
                  'These answers guide support suggestions and follow-up tone.',
              children: [
                _ChoiceField(
                  palette: palette,
                  question: 'When you feel low, what do you usually do first?',
                  value: _copingStyle,
                  options: copingStyleOptions,
                  onChanged: (value) => setState(() => _copingStyle = value),
                ),
                _ChoiceField(
                  palette: palette,
                  question: 'How easy is it for you to ask for help?',
                  value: _helpSeekingEase,
                  options: helpSeekingOptions,
                  onChanged: (value) =>
                      setState(() => _helpSeekingEase = value),
                ),
                _ChoiceField(
                  palette: palette,
                  question:
                      'How connected do you usually feel to friends or classmates?',
                  value: _socialConnectedness,
                  options: connectednessOptions,
                  onChanged: (value) =>
                      setState(() => _socialConnectedness = value),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _ChoiceSection(
              palette: palette,
              title: 'Support preferences',
              subtitle:
                  'This decides what the app should prioritize first when it responds.',
              children: [
                _ChoiceField(
                  palette: palette,
                  question: 'What kind of support feels most comfortable?',
                  value: _supportPreference,
                  options: supportPreferenceOptions,
                  onChanged: (value) =>
                      setState(() => _supportPreference = value),
                ),
                _ChoiceField(
                  palette: palette,
                  question:
                      'If BAHA checks in a little more closely on one area, what should it be?',
                  value: _checkinFocus,
                  options: checkinFocusOptions,
                  onChanged: (value) => setState(() => _checkinFocus = value),
                ),
              ],
            ),
            const SizedBox(height: 18),
            AnimatedPrimaryButton(
              label: 'Save profile and continue',
              icon: Icons.check_rounded,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceSection extends StatelessWidget {
  const _ChoiceSection({
    required this.palette,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final PrototypePalette palette;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(title: title, subtitle: subtitle),
          ...children,
        ],
      ),
    );
  }
}

class _ChoiceField extends StatelessWidget {
  const _ChoiceField({
    required this.palette,
    required this.question,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final PrototypePalette palette;
  final String question;
  final String? value;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.entries.map((entry) {
              final selected = entry.key == value;
              return ChoiceChip(
                label: Text(entry.value),
                selected: selected,
                onSelected: (_) => onChanged(entry.key),
                selectedColor: palette.primary.withValues(alpha: .22),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
