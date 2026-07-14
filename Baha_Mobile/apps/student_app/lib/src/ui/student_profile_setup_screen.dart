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
  late String _experiencesPeriods;
  String? _periodImpact;
  late String _helpSeekingEase;
  late String _socialConnectedness;

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
    _experiencesPeriods = initial?.experiencesPeriods ?? 'prefer_not_to_say';
    _periodImpact = initial?.periodImpact;
    _helpSeekingEase = initial?.helpSeekingEase ?? 'mixed';
    _socialConnectedness = initial?.socialConnectedness ?? 'mostly_connected';
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
        mainPhysicalIssue: _deriveMainPhysicalIssue(),
        experiencesPeriods: _experiencesPeriods,
        periodImpact: _experiencesPeriods == 'yes' ? _periodImpact : null,
        copingStyle: _deriveCopingStyle(),
        helpSeekingEase: _helpSeekingEase,
        socialConnectedness: _socialConnectedness,
        supportPreference: _deriveSupportPreference(),
        checkinFocus: _deriveCheckinFocus(),
      ),
    );
  }

  String _deriveMainPhysicalIssue() {
    if (_experiencesPeriods == 'yes' &&
        (_periodImpact == 'often' || _periodImpact == 'a_lot')) {
      return 'chronic_condition';
    }
    if (_schoolDaySleepQuality == 'poor' ||
        _schoolDaySleepQuality == 'very_poor') {
      return 'poor_sleep';
    }
    return 'none';
  }

  String _deriveCopingStyle() {
    if (_trustedSupportPerson == 'friend' ||
        _trustedSupportPerson == 'teacher_counselor' ||
        _trustedSupportPerson == 'parent_guardian') {
      return 'talk_to_someone';
    }
    if (_helpSeekingEase == 'hard' || _helpSeekingEase == 'very_hard') {
      return 'stay_alone';
    }
    return 'phone_or_music';
  }

  String _deriveSupportPreference() {
    if (_helpSeekingEase == 'very_easy' ||
        _helpSeekingEase == 'somewhat_easy') {
      return 'trusted_adult';
    }
    if (_ageBand == '9_12') {
      return 'activities_games';
    }
    return 'quick_tips';
  }

  String _deriveCheckinFocus() {
    if (_schoolDaySleepQuality == 'poor' ||
        _schoolDaySleepQuality == 'very_poor') {
      return 'sleep';
    }
    if (_weeklyStressFrequency == 'often' ||
        _weeklyStressFrequency == 'very_often' ||
        _weeklyStressFrequency == 'almost_every_day') {
      return 'stress';
    }
    if (_socialConnectedness == 'a_bit_isolated' ||
        _socialConnectedness == 'very_isolated' ||
        _mainPressure == 'friends') {
      return 'connectedness';
    }
    if (_mainPressure == 'health') {
      return 'physical_wellbeing';
    }
    return 'mood';
  }

  bool get _shouldAskPeriodsQuestion => _genderIdentity != 'male';

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
              subtitle:
                  'Only the context needed to phrase questions appropriately and interpret patterns responsibly.',
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
                  onChanged: (value) {
                    setState(() {
                      _genderIdentity = value;
                      if (!_shouldAskPeriodsQuestion) {
                        _experiencesPeriods = 'no';
                        _periodImpact = null;
                      } else if (_experiencesPeriods == 'no') {
                        _experiencesPeriods = 'prefer_not_to_say';
                      }
                    });
                  },
                ),
                _ChoiceField(
                  palette: palette,
                  question:
                      'Who do you usually go to first when something feels off?',
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
              subtitle:
                  'This becomes the baseline that future daily check-ins are compared against.',
              children: [
                _ChoiceField(
                  palette: palette,
                  question: 'On a normal school week, how is your sleep?',
                  value: _schoolDaySleepQuality,
                  options: baselineScaleOptions,
                  onChanged: (value) =>
                      setState(() => _schoolDaySleepQuality = value),
                ),
                _ChoiceField(
                  palette: palette,
                  question: 'On most days, how is your energy?',
                  value: _usualEnergy,
                  options: baselineScaleOptions,
                  onChanged: (value) => setState(() => _usualEnergy = value),
                ),
                _ChoiceField(
                  palette: palette,
                  question: 'How often do you feel stressed in a usual week?',
                  value: _weeklyStressFrequency,
                  options: stressFrequencyOptions,
                  onChanged: (value) =>
                      setState(() => _weeklyStressFrequency = value),
                ),
                _ChoiceField(
                  palette: palette,
                  question: 'What tends to affect you the most lately?',
                  value: _mainPressure,
                  options: mainPressureOptions,
                  onChanged: (value) => setState(() => _mainPressure = value),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _ChoiceSection(
              palette: palette,
              title: 'Social and help context',
              subtitle:
                  'This helps BAHA understand whether low mood or stress is more likely to stay private, social, or harder to raise.',
              children: [
                _ChoiceField(
                  palette: palette,
                  question:
                      'How connected do you usually feel to friends or classmates?',
                  value: _socialConnectedness,
                  options: connectednessOptions,
                  onChanged: (value) =>
                      setState(() => _socialConnectedness = value),
                ),
                _ChoiceField(
                  palette: palette,
                  question: 'How easy is it for you to ask for help?',
                  value: _helpSeekingEase,
                  options: helpSeekingOptions,
                  onChanged: (value) =>
                      setState(() => _helpSeekingEase = value),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _ChoiceSection(
              palette: palette,
              title: 'Physical context',
              subtitle:
                  'Only asked because it changes how physical wellbeing answers get interpreted later.',
              children: [
                if (_shouldAskPeriodsQuestion) ...[
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
                          'When they happen, how much do periods affect energy, pain, or mood?',
                      value: _periodImpact,
                      options: periodImpactOptions,
                      onChanged: (value) =>
                          setState(() => _periodImpact = value),
                    ),
                ] else
                  Text(
                    'No additional physical-context question is needed here.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: palette.muted),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            AnimatedPrimaryButton(
              label: 'Finish onboarding',
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
