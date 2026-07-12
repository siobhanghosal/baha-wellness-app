import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const genderIdentityOptions = <String, String>{
  'male': 'Male',
  'female': 'Female',
  'prefer_not_to_say': 'Prefer not to say',
};

const trustedSupportOptions = <String, String>{
  'parent_guardian': 'Parent or guardian',
  'sibling_family': 'Sibling or family member',
  'friend': 'Friend',
  'teacher_counselor': 'Teacher or counselor',
  'no_one': 'No one regularly',
};

const baselineScaleOptions = <String, String>{
  'very_good': 'Very good',
  'good': 'Good',
  'okay': 'Okay',
  'poor': 'Poor',
  'very_poor': 'Very poor',
};

const stressFrequencyOptions = <String, String>{
  'rarely': 'Rarely',
  'sometimes': 'Sometimes',
  'often': 'Often',
  'very_often': 'Very often',
  'almost_every_day': 'Almost every day',
};

const mainPressureOptions = <String, String>{
  'school': 'School or studies',
  'friends': 'Friends',
  'family': 'Family',
  'health': 'Health or body',
  'social_media': 'Social media',
  'nothing_specific': 'Nothing specific',
};

const physicalIssueOptions = <String, String>{
  'headaches': 'Headaches',
  'stomach_issues': 'Stomach issues',
  'poor_sleep': 'Poor sleep',
  'low_appetite': 'Low appetite',
  'chronic_condition': 'A chronic condition',
  'none': 'None of these',
};

const yesNoUnknownOptions = <String, String>{
  'yes': 'Yes',
  'no': 'No',
  'prefer_not_to_say': 'Prefer not to say',
};

const periodImpactOptions = <String, String>{
  'not_really': 'Not really',
  'a_little': 'A little',
  'sometimes': 'Sometimes',
  'often': 'Often',
  'a_lot': 'A lot',
};

const copingStyleOptions = <String, String>{
  'talk_to_someone': 'Talk to someone',
  'stay_alone': 'Stay alone',
  'phone_or_music': 'Use my phone or music',
  'sleep_or_rest': 'Sleep or rest',
  'distract_myself': 'Distract myself',
  'not_sure': 'Not sure',
};

const helpSeekingOptions = <String, String>{
  'very_easy': 'Very easy',
  'somewhat_easy': 'Somewhat easy',
  'mixed': 'Mixed',
  'hard': 'Hard',
  'very_hard': 'Very hard',
};

const connectednessOptions = <String, String>{
  'very_connected': 'Very connected',
  'mostly_connected': 'Mostly connected',
  'mixed': 'Mixed',
  'a_bit_isolated': 'A bit isolated',
  'very_isolated': 'Very isolated',
};

const supportPreferenceOptions = <String, String>{
  'quick_tips': 'Quick tips',
  'activities_games': 'Activities and games',
  'journaling_checkins': 'Journaling and check-ins',
  'trusted_adult': 'Talking to a trusted adult',
  'professional_support': 'Professional support',
};

const checkinFocusOptions = <String, String>{
  'sleep': 'Sleep',
  'stress': 'Stress',
  'mood': 'Mood',
  'physical_wellbeing': 'Physical health',
  'connectedness': 'Friendships',
  'no_preference': 'No preference',
};

class StudentWellbeingProfile {
  const StudentWellbeingProfile({
    required this.ageBand,
    required this.genderIdentity,
    required this.trustedSupportPerson,
    required this.schoolDaySleepQuality,
    required this.usualEnergy,
    required this.weeklyStressFrequency,
    required this.mainPressure,
    required this.mainPhysicalIssue,
    required this.experiencesPeriods,
    required this.copingStyle,
    required this.helpSeekingEase,
    required this.socialConnectedness,
    required this.supportPreference,
    required this.checkinFocus,
    this.periodImpact,
    this.createdAtIso8601,
    this.updatedAtIso8601,
  });

  final String ageBand;
  final String genderIdentity;
  final String trustedSupportPerson;
  final String schoolDaySleepQuality;
  final String usualEnergy;
  final String weeklyStressFrequency;
  final String mainPressure;
  final String mainPhysicalIssue;
  final String experiencesPeriods;
  final String? periodImpact;
  final String copingStyle;
  final String helpSeekingEase;
  final String socialConnectedness;
  final String supportPreference;
  final String checkinFocus;
  final String? createdAtIso8601;
  final String? updatedAtIso8601;

  bool get hasProfile => true;

  bool get periodsRelevant => experiencesPeriods == 'yes';

  List<String> get profileTags {
    final tags = <String>{};
    if (schoolDaySleepQuality == 'poor' ||
        schoolDaySleepQuality == 'very_poor') {
      tags.add('sleep_vulnerable');
    }
    if (usualEnergy == 'poor' || usualEnergy == 'very_poor') {
      tags.add('energy_vulnerable');
    }
    if (weeklyStressFrequency == 'often' ||
        weeklyStressFrequency == 'very_often' ||
        weeklyStressFrequency == 'almost_every_day') {
      tags.add('stress_vulnerable');
    }
    if (mainPressure == 'school') {
      tags.add('school_pressure_driven');
    }
    if (mainPressure == 'friends') {
      tags.add('friendship_pressure_driven');
    }
    if (mainPressure == 'family') {
      tags.add('family_pressure_driven');
    }
    if (mainPhysicalIssue != 'none') {
      tags.add('somatic_signal_prone');
    }
    if (periodsRelevant &&
        (periodImpact == 'often' || periodImpact == 'a_lot')) {
      tags.add('period_linked_physical_impact');
    }
    if (helpSeekingEase == 'hard' || helpSeekingEase == 'very_hard') {
      tags.add('low_help_seeking');
    }
    if (socialConnectedness == 'a_bit_isolated' ||
        socialConnectedness == 'very_isolated') {
      tags.add('social_isolation_risk');
    }
    if (supportPreference == 'activities_games') {
      tags.add('engagement_prefers_activity');
    }
    if (checkinFocus != 'no_preference') {
      tags.add('focus_$checkinFocus');
    }
    return tags.toList()..sort();
  }

  String get supportPreferenceLabel =>
      supportPreferenceOptions[supportPreference] ?? supportPreference;

  String get checkinFocusLabel =>
      checkinFocusOptions[checkinFocus] ?? checkinFocus;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'age_band': ageBand,
      'gender_identity': genderIdentity,
      'trusted_support_person': trustedSupportPerson,
      'school_day_sleep_quality': schoolDaySleepQuality,
      'usual_energy': usualEnergy,
      'weekly_stress_frequency': weeklyStressFrequency,
      'main_pressure': mainPressure,
      'main_physical_issue': mainPhysicalIssue,
      'experiences_periods': experiencesPeriods,
      'period_impact': periodImpact,
      'coping_style': copingStyle,
      'help_seeking_ease': helpSeekingEase,
      'social_connectedness': socialConnectedness,
      'support_preference': supportPreference,
      'checkin_focus': checkinFocus,
      'created_at': createdAtIso8601,
      'updated_at': updatedAtIso8601,
      'profile_tags': profileTags,
    };
  }

  Map<String, dynamic> toBootstrapMetadata() {
    return <String, dynamic>{
      'wellbeing_profile': toJson(),
      'wellbeing_profile_version': 1,
    };
  }

  StudentWellbeingProfile copyWith({
    String? ageBand,
    String? genderIdentity,
    String? trustedSupportPerson,
    String? schoolDaySleepQuality,
    String? usualEnergy,
    String? weeklyStressFrequency,
    String? mainPressure,
    String? mainPhysicalIssue,
    String? experiencesPeriods,
    String? periodImpact,
    String? copingStyle,
    String? helpSeekingEase,
    String? socialConnectedness,
    String? supportPreference,
    String? checkinFocus,
    String? createdAtIso8601,
    String? updatedAtIso8601,
  }) {
    return StudentWellbeingProfile(
      ageBand: ageBand ?? this.ageBand,
      genderIdentity: genderIdentity ?? this.genderIdentity,
      trustedSupportPerson: trustedSupportPerson ?? this.trustedSupportPerson,
      schoolDaySleepQuality:
          schoolDaySleepQuality ?? this.schoolDaySleepQuality,
      usualEnergy: usualEnergy ?? this.usualEnergy,
      weeklyStressFrequency:
          weeklyStressFrequency ?? this.weeklyStressFrequency,
      mainPressure: mainPressure ?? this.mainPressure,
      mainPhysicalIssue: mainPhysicalIssue ?? this.mainPhysicalIssue,
      experiencesPeriods: experiencesPeriods ?? this.experiencesPeriods,
      periodImpact: periodImpact ?? this.periodImpact,
      copingStyle: copingStyle ?? this.copingStyle,
      helpSeekingEase: helpSeekingEase ?? this.helpSeekingEase,
      socialConnectedness: socialConnectedness ?? this.socialConnectedness,
      supportPreference: supportPreference ?? this.supportPreference,
      checkinFocus: checkinFocus ?? this.checkinFocus,
      createdAtIso8601: createdAtIso8601 ?? this.createdAtIso8601,
      updatedAtIso8601: updatedAtIso8601 ?? this.updatedAtIso8601,
    );
  }

  factory StudentWellbeingProfile.fromJson(Map<String, dynamic> json) {
    return StudentWellbeingProfile(
      ageBand: json['age_band'] as String? ?? '13_14',
      genderIdentity: json['gender_identity'] as String? ?? 'prefer_not_to_say',
      trustedSupportPerson:
          json['trusted_support_person'] as String? ?? 'parent_guardian',
      schoolDaySleepQuality:
          json['school_day_sleep_quality'] as String? ?? 'okay',
      usualEnergy: json['usual_energy'] as String? ?? 'okay',
      weeklyStressFrequency:
          json['weekly_stress_frequency'] as String? ?? 'sometimes',
      mainPressure: json['main_pressure'] as String? ?? 'school',
      mainPhysicalIssue: json['main_physical_issue'] as String? ?? 'none',
      experiencesPeriods:
          json['experiences_periods'] as String? ?? 'prefer_not_to_say',
      periodImpact: json['period_impact'] as String?,
      copingStyle: json['coping_style'] as String? ?? 'talk_to_someone',
      helpSeekingEase: json['help_seeking_ease'] as String? ?? 'mixed',
      socialConnectedness:
          json['social_connectedness'] as String? ?? 'mostly_connected',
      supportPreference: json['support_preference'] as String? ?? 'quick_tips',
      checkinFocus: json['checkin_focus'] as String? ?? 'no_preference',
      createdAtIso8601: json['created_at'] as String?,
      updatedAtIso8601: json['updated_at'] as String?,
    );
  }
}

class StudentWellbeingProfileStore {
  StudentWellbeingProfileStore({this._seedPreferences});

  final SharedPreferences? _seedPreferences;
  SharedPreferences? _preferences;

  static const _storagePrefix = 'baha.student.wellbeing_profile.';

  Future<StudentWellbeingProfile?> load(String externalAuthId) async {
    final preferences = await _getPreferences();
    final raw = preferences.getString(_storageKey(externalAuthId));
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    return StudentWellbeingProfile.fromJson(decoded);
  }

  Future<void> save({
    required String externalAuthId,
    required StudentWellbeingProfile profile,
  }) async {
    final preferences = await _getPreferences();
    final now = DateTime.now().toUtc().toIso8601String();
    final payload = profile
        .copyWith(
          createdAtIso8601: profile.createdAtIso8601 ?? now,
          updatedAtIso8601: now,
        )
        .toJson();
    await preferences.setString(
      _storageKey(externalAuthId),
      jsonEncode(payload),
    );
  }

  Future<void> clear(String externalAuthId) async {
    final preferences = await _getPreferences();
    await preferences.remove(_storageKey(externalAuthId));
  }

  Future<SharedPreferences> _getPreferences() async {
    _preferences ??= _seedPreferences ?? await SharedPreferences.getInstance();
    return _preferences!;
  }

  String _storageKey(String externalAuthId) => '$_storagePrefix$externalAuthId';
}
