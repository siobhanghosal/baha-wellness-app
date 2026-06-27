import '../models/prototype_models.dart';

enum BlueprintStatus { ready, partial, missing }

class ScreenBlueprint {
  const ScreenBlueprint({
    required this.screenId,
    required this.role,
    required this.title,
    required this.purpose,
    required this.backendContracts,
    required this.permission,
    required this.behaviors,
    required this.status,
    this.notes = const [],
  });

  final String screenId;
  final AppRole role;
  final String title;
  final String purpose;
  final List<String> backendContracts;
  final String permission;
  final List<String> behaviors;
  final BlueprintStatus status;
  final List<String> notes;
}

const screenBlueprints = <ScreenBlueprint>[
  ScreenBlueprint(
    screenId: 'ST-006',
    role: AppRole.student,
    title: 'Student Home Dashboard',
    purpose: 'Show the latest weekly summary, trend headline, recent check-ins, and next safe actions.',
    backendContracts: [
      'GET /mobile/me',
      'GET /mobile/student/weekly-summary/latest',
      'GET /mobile/student/checkins',
    ],
    permission: 'Active student',
    behaviors: [
      'Render a private weekly summary with role-safe language.',
      'Offer quick entry to Check-In, Buddy, and support.',
      'Fall back gracefully when the latest summary is unavailable.',
    ],
    status: BlueprintStatus.ready,
  ),
  ScreenBlueprint(
    screenId: 'ST-007',
    role: AppRole.student,
    title: 'Daily Check-in',
    purpose: 'List available check-in templates and previously submitted check-ins.',
    backendContracts: [
      'GET /mobile/student/checkin-templates',
      'GET /mobile/student/checkins',
    ],
    permission: 'Active student',
    behaviors: [
      'Show first-time and returning check-in states.',
      'Let the user open a check-in template detail flow.',
      'Keep draft and retry behavior local until submission succeeds.',
    ],
    status: BlueprintStatus.ready,
  ),
  ScreenBlueprint(
    screenId: 'ST-011',
    role: AppRole.student,
    title: 'Learn Feed',
    purpose: 'Surface discovery cards, approved content, and active modules.',
    backendContracts: [
      'GET /mobile/content/feed',
      'GET /mobile/student/modules',
      'GET /mobile/content/{content_item_id}',
    ],
    permission: 'Active student',
    behaviors: [
      'Show lightweight discovery content and full modules together.',
      'Track progress and return to modules later.',
      'Keep all guidance evidence-based and BAHA-approved.',
    ],
    status: BlueprintStatus.ready,
  ),
  ScreenBlueprint(
    screenId: 'ST-013',
    role: AppRole.student,
    title: 'BAHA Buddy',
    purpose: 'Let students resume or start a support conversation with safe backend-driven escalation.',
    backendContracts: [
      'GET /mobile/chat/sessions',
      'POST /mobile/chat/sessions',
      'GET /mobile/chat/sessions/{session_id}/messages',
      'POST /mobile/chat/sessions/{session_id}/messages',
    ],
    permission: 'Active student',
    behaviors: [
      'Persist chat sessions and messages.',
      'Do not run crisis logic client-side beyond messaging and connectivity handling.',
      'Let the backend create signals and escalation cases when needed.',
    ],
    status: BlueprintStatus.ready,
  ),
  ScreenBlueprint(
    screenId: 'ST-015',
    role: AppRole.student,
    title: 'SOS Help',
    purpose: 'Show support contacts and create a direct help request.',
    backendContracts: [
      'GET /mobile/support-contacts',
      'POST /mobile/student/help-requests',
    ],
    permission: 'Active student',
    behaviors: [
      'Offer support contacts first.',
      'Let a student submit a clear help request.',
      'Map the request into the counselor queue later.',
    ],
    status: BlueprintStatus.ready,
  ),
  ScreenBlueprint(
    screenId: 'PA-003',
    role: AppRole.parent,
    title: 'Parent Home',
    purpose: 'Show linked students and a consent-gated parent-safe summary.',
    backendContracts: [
      'GET /mobile/parent/students',
      'GET /mobile/parent/students/{student_profile_id}/weekly-summary/latest',
    ],
    permission: 'Active guardian',
    behaviors: [
      'Select the active child context.',
      'Show only parent-safe summary data.',
      'Avoid exposing raw student check-ins or private entries.',
    ],
    status: BlueprintStatus.ready,
  ),
  ScreenBlueprint(
    screenId: 'PA-005',
    role: AppRole.parent,
    title: 'Summary Sharing Consent',
    purpose: 'Let guardians understand and manage summary sharing state.',
    backendContracts: [
      'GET /auth/guardian/consent/parent-summary-sharing/{student_profile_id}',
      'POST /auth/guardian/consent/parent-summary-sharing',
    ],
    permission: 'Active guardian',
    behaviors: [
      'Show whether sharing is pending, granted, declined, or withdrawn.',
      'Explain what the parent can and cannot see.',
      'Keep consent explicit and reversible.',
    ],
    status: BlueprintStatus.ready,
  ),
  ScreenBlueprint(
    screenId: 'PA-007',
    role: AppRole.parent,
    title: 'Parent Resources',
    purpose: 'Provide parent-safe guides and conversation supports.',
    backendContracts: [
      'GET /mobile/content/feed?content_type=conversation_guide',
      'GET /mobile/content/{content_item_id}',
    ],
    permission: 'Active guardian',
    behaviors: [
      'Show only role-safe content.',
      'Prioritize practical conversation guidance.',
      'Present resources as family support, not diagnosis.',
    ],
    status: BlueprintStatus.ready,
  ),
  ScreenBlueprint(
    screenId: 'TE-003',
    role: AppRole.teacher,
    title: 'Class List',
    purpose: 'Show assigned classes and direct the teacher into class-scoped wellbeing views.',
    backendContracts: ['GET /mobile/teacher/classes'],
    permission: 'Active teacher',
    behaviors: [
      'Use class assignment as the primary context.',
      'Keep classroom and pastoral framing clear.',
      'Avoid implying unrestricted student wellness access.',
    ],
    status: BlueprintStatus.ready,
  ),
  ScreenBlueprint(
    screenId: 'TE-005',
    role: AppRole.teacher,
    title: 'Student Wellbeing Signals',
    purpose: 'Show targetable students for pastoral action inside assigned classes.',
    backendContracts: ['GET /mobile/teacher/classes/{class_id}/students'],
    permission: 'Active teacher assigned to class',
    behaviors: [
      'List class students with workflow-safe context.',
      'Open pastoral follow-up actions instead of diagnostic profiles.',
      'Keep access school-scoped and role-safe.',
    ],
    status: BlueprintStatus.ready,
  ),
  ScreenBlueprint(
    screenId: 'TE-006',
    role: AppRole.teacher,
    title: 'Pastoral Flag',
    purpose: 'Capture a teacher observation for counselor follow-up.',
    backendContracts: ['POST /mobile/teacher/pastoral-flags'],
    permission: 'Active teacher',
    behaviors: [
      'Use non-diagnostic language.',
      'Submit class-linked pastoral observations.',
      'Route the observation for counselor review later.',
    ],
    status: BlueprintStatus.ready,
  ),
  ScreenBlueprint(
    screenId: 'TE-007',
    role: AppRole.teacher,
    title: 'Teacher Resources',
    purpose: 'Provide teacher-safe content and support material.',
    backendContracts: [
      'GET /mobile/content/feed?audience_app=teacher',
      'GET /mobile/content/{content_item_id}?audience_app=teacher',
    ],
    permission: 'Active teacher',
    behaviors: [
      'Emphasize class support and intervention framing.',
      'Keep resources role-specific.',
      'Separate class trends from individual student privacy.',
    ],
    status: BlueprintStatus.ready,
  ),
  ScreenBlueprint(
    screenId: 'CO-003',
    role: AppRole.admin,
    title: 'BAHA Command Center',
    purpose: 'Show the latest pilot metrics for counselor and BAHA operational work.',
    backendContracts: ['GET /mobile/counselor/dashboard/latest'],
    permission: 'Counselor, administrator, or BAHA admin',
    behaviors: [
      'Present school or global operational metrics.',
      'Act as the landing view for queue and approvals.',
      'Stay operational, not student-facing.',
    ],
    status: BlueprintStatus.ready,
  ),
  ScreenBlueprint(
    screenId: 'CO-004',
    role: AppRole.admin,
    title: 'Support Queue',
    purpose: 'Surface open cases, signals, and help requests for operational follow-up.',
    backendContracts: ['GET /mobile/counselor/queue'],
    permission: 'Counselor, administrator, or BAHA admin',
    behaviors: [
      'Combine cases, unresolved signals, and help requests.',
      'Stay school-scoped for non-BAHA roles.',
      'Support filtering and triage later.',
    ],
    status: BlueprintStatus.ready,
  ),
  ScreenBlueprint(
    screenId: 'CO-007',
    role: AppRole.admin,
    title: 'Approval Requests',
    purpose: 'Review teacher and counselor activation requests.',
    backendContracts: ['GET /auth/approval-requests'],
    permission: 'Administrator or BAHA admin',
    behaviors: [
      'List pending access requests.',
      'Open a governed review workflow.',
      'Refresh the queue after a decision.',
    ],
    status: BlueprintStatus.ready,
  ),
  ScreenBlueprint(
    screenId: 'CO-008',
    role: AppRole.admin,
    title: 'Approval Decision',
    purpose: 'Approve or reject activation and access requests.',
    backendContracts: ['POST /auth/approval-requests/{request_id}/decision'],
    permission: 'Administrator or BAHA admin',
    behaviors: [
      'Allow approve and reject actions.',
      'Persist reviewer intent and notes later.',
      'Return the reviewer to the refreshed queue.',
    ],
    status: BlueprintStatus.ready,
  ),
  ScreenBlueprint(
    screenId: 'CO-009',
    role: AppRole.admin,
    title: 'Operational Content',
    purpose: 'Read operational and counselor-safe content.',
    backendContracts: [
      'GET /mobile/content/feed?audience_app=counselor',
      'GET /mobile/content/{content_item_id}?audience_app=counselor',
    ],
    permission: 'Counselor, administrator, or BAHA admin',
    behaviors: [
      'Show read-only operational content for now.',
      'Keep publication and review actions separate.',
      'Reserve mutation flows for a later slice.',
    ],
    status: BlueprintStatus.partial,
    notes: ['Content review workflow is still a later backend slice.'],
  ),
];

ScreenBlueprint? findBlueprint(AppRole role, String title) {
  final normalized = _normalize(title);
  for (final blueprint in screenBlueprints) {
    if (blueprint.role != role) {
      continue;
    }
    final target = _normalize(blueprint.title);
    if (normalized == target) {
      return blueprint;
    }
    if (_titleAliases[normalized]?.contains(blueprint.screenId) ?? false) {
      return blueprint;
    }
  }
  return null;
}

String _normalize(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

const _titleAliases = <String, List<String>>{
  'mood': ['ST-006'],
  'sleep': ['ST-006'],
  'stress': ['ST-006'],
  'energy': ['ST-006'],
  'check in rhythm': ['PA-003'],
  'sleep pattern': ['PA-003'],
  'learning': ['PA-007'],
  'class calm index': ['TE-003'],
  'attendance': ['TE-003'],
  'pastoral flags': ['TE-006'],
  'daily check in': ['ST-007'],
  'learn feed': ['ST-011'],
  'sleep reset': ['ST-011'],
  'digital wellness': ['ST-011'],
  'peer pressure': ['ST-011'],
  'exam stress': ['ST-011'],
  'baha buddy': ['ST-013'],
  'sos help': ['ST-015'],
  'reports and insights': ['PA-003'],
  'summary sharing consent': ['PA-005'],
  'parent resources': ['PA-007'],
  'classes': ['TE-003'],
  'student wellbeing signals': ['TE-005'],
  'teacher resources': ['TE-007'],
  'tasks': ['TE-007'],
  'class report': ['TE-003'],
  'baha command center': ['CO-003'],
  'support queue': ['CO-004'],
  'approval requests': ['CO-007'],
  'approval decision': ['CO-008'],
  'content': ['CO-009'],
  'operational content': ['CO-009'],
};

List<String> onboardingStepsFor(AppRole role) => switch (role) {
  AppRole.student => [
      'Welcome and trust framing',
      'Age cohort and consent band',
      'Privacy explanation and acknowledgement',
      'Guardian consent wait or self-consent path',
      'Dashboard unlock',
    ],
  AppRole.parent => [
      'Bootstrap parent identity',
      'Link child account',
      'Confirm relationship and consent authority',
      'Configure summary sharing and privacy reminders',
      'Enter parent dashboard',
    ],
  AppRole.teacher => [
      'Bootstrap teacher identity',
      'Approval-pending check',
      'Class assignment setup',
      'Pastoral visibility guidance',
      'Enter teacher workspace',
    ],
  AppRole.admin => [
      'Bootstrap counselor or BAHA identity',
      'Approval-pending check',
      'Open operations dashboard',
      'Review queue and access requests',
      'Enter command center',
    ],
};
