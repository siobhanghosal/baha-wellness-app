import 'package:baha_shared_models/baha_shared_models.dart';
import 'package:test/test.dart';

void main() {
  test('maps onboarding JSON payload into a model', () {
    final state = AuthOnboardingState.fromJson(const {
      'has_baha_user': true,
      'identity_match_mode': 'external_auth_id',
      'external_auth_id': 'supabase-student-demo',
      'roles': ['student'],
      'approval_status': 'not_required',
      'consent_status': 'pending',
      'guardian_link_status': 'pending',
      'linked_student_count': 0,
      'linked_guardian_count': 0,
      'next_step': 'await_guardian_consent',
      'display_name': 'Student Demo',
    });

    expect(state.hasBahaUser, isTrue);
    expect(state.displayName, 'Student Demo');
    expect(state.requiresBootstrap, isFalse);
    expect(state.requiresAttention, isTrue);
  });
}
