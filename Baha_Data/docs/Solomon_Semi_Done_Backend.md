# Solomon Semi Done Backend

## Status

This file records the implemented BAHA Wellness Companion backend and cloud-integration work completed up to this checkpoint.

Branch name:

```text
Solomon_Semi_Done_Backend
```

## Implemented Backend Work

### Data Acquisition Platform

Implemented a production-oriented acquisition platform for the BAHA knowledge corpus.

Completed capabilities:

- Approved-source registry.
- Public-source acquisition workflow.
- WHO, AHA/IAP, NIMHANS, Tier-3, life-skills, and digital-wellbeing acquisition campaigns.
- Research discovery and collection workflow.
- PDF, HTML, guideline, toolkit, report, and educational resource acquisition paths.
- Quality status tracking.
- Topic and source coverage tracking.
- Knowledge graph extraction and expansion.
- Condition profile extraction.
- Corpus reporting and coverage/gap reports.

Current collected corpus checkpoint from the working system:

- Accepted resources: 8,026
- Research papers: 1,066
- PDFs: 1,533
- Knowledge graph nodes: 124,959
- Knowledge graph edges: 620,009
- Condition profiles: 28

Embeddings were intentionally deferred when requested. The app and backend are prepared to integrate embeddings later.

### Supabase Cloud Setup

Supabase project connected:

```text
tolpvdydpedukuvxvdjw
```

Applied migrations to the hosted Supabase database using the local Supabase CLI.

Applied migration groups:

- Auth and user management.
- Parent guardianship core.
- Product runtime foundation.
- Mobile runtime seed content.
- Onboarding and account creation.

Migration added in this checkpoint:

```text
Baha_Data/supabase/migrations/20260624131500_onboarding_account_creation.sql
Baha_Data/migrations/021_account_onboarding_creation.sql
```

### Authentication Foundation

Extended existing authentication instead of replacing it.

Implemented:

- Supabase Auth remains the source of truth for password/session management.
- FastAPI JWT validation continues to use Supabase access tokens.
- Role-aware auth actor handling.
- `platform_admin` compatibility while preserving existing `admin` behavior.
- Role-based route protection.
- Profile lookup through Supabase PostgreSQL.

Passwords are not stored manually in BAHA tables.

### Account Creation and Onboarding

Implemented production-grade signup/onboarding support for:

- Student
- Parent / Guardian
- Teacher
- Counselor
- School Admin

Platform Admin public signup remains disabled by design.

Student signup supports:

- Full name
- Age
- Gender
- Grade
- School
- Email
- Password
- Age group routing
- Minor consent gating

Parent signup supports:

- Full name
- Email
- Mobile number
- Relationship to student
- Child account linking
- Consent management

Teacher signup supports:

- School email
- Employee ID
- School
- Department
- School admin approval workflow

Counselor signup supports:

- Professional email
- Organization
- License / registration number
- Platform admin approval workflow

School admin signup supports:

- School name
- School email
- Designation
- Platform admin approval workflow

### Consent System

Implemented minor consent state in the account workflow.

Consent statuses:

- `not_required`
- `pending`
- `approved`
- `revoked`

Students below 18 are held behind consent until a linked parent/guardian approves.

### Approval Workflow

Implemented approval request storage and API workflow.

Approval statuses:

- `not_required`
- `pending`
- `approved`
- `rejected`
- `revoked`

Pending approval applies to:

- Teacher accounts
- Counselor accounts
- School admin accounts

### Database Additions

Added or extended:

- `profiles`
- `parents`
- `school_admins`
- `approval_requests`
- `guardian_student_links` compatibility view
- Consent and approval status columns
- Profile metadata columns
- RLS policies for onboarding tables
- Trigger-compatible role shadow record support

### FastAPI Endpoints

Implemented or extended:

- `GET /auth/me`
- `PATCH /auth/profile`
- `POST /auth/signup-profile`
- `GET /auth/onboarding-state`
- `POST /auth/parent/link-child`
- `POST /auth/consent`
- `GET /auth/approval-requests`
- `POST /auth/approval-requests/{request_id}/decision`

### Mobile Runtime Backend

Implemented cloud-facing mobile runtime contracts for:

- Student dashboard
- Student profile
- Student check-ins
- Student learning modules
- Student help requests
- Parent dashboard
- Parent linked students
- Teacher dashboard
- Teacher classes
- Teacher pastoral flags
- Counselor dashboard
- Counselor support queue
- Counselor case notes
- Chat sessions/messages
- Notifications

### Flutter App Work

Implemented a Flutter mobile app architecture with dedicated app surfaces:

- Student App
- Parent App
- Teacher App
- BAHA/Counselor Dashboard

Implemented:

- Supabase initialization.
- Render API base URL configuration.
- Role-locked login.
- Signup screens.
- Email verification screen.
- Consent pending screen.
- Approval pending screen.
- Account linked screen.
- Child link screen.
- Session persistence through Supabase.
- GoRouter route guards.
- Riverpod providers.
- Age-adaptive Student App UI.
- Parent, Teacher, Counselor, and Admin dashboard surfaces.

Android flavors/package IDs were configured so dedicated apps can install side by side.

### Phone Testing

Wireless Android phone testing was completed.

Detected device:

```text
SM S731B
192.168.1.117:45261
```

Student app package installed:

```text
org.baha.wellness.student
```

Student APK built and launched successfully on the physical phone.

### Validation

Backend checks passed:

```text
8 passed
```

Flutter checks passed:

```text
flutter analyze
No issues found
```

Supabase migrations applied successfully after fixing one SQL expression-index issue in the initial auth migration.

## Important Security Notes

Secrets were used locally for Supabase CLI/database setup. Rotate these before production handoff:

- Supabase personal access token.
- Supabase database password.

Do not commit secrets into GitHub.

## Not Fully Complete Yet

The following are intentionally not finished or still require the next phase:

- Full production RAG/vector embedding activation.
- Production-grade release signing for Android apps.
- Complete Play Store packaging.
- Full end-to-end QA across all four role apps.
- Google Sign-In and Apple Sign-In provider credentials.
- MFA enforcement UI.
- Admin-created platform admin workflow UI.
- Full counselor/school-admin approval dashboard UX.
- Live notification delivery.
- Production monitoring/alerting.
- Final clinical review workflows.

## Next Recommended Steps

1. Rotate Supabase credentials used during setup.
2. Redeploy Render backend so the latest FastAPI endpoints are live.
3. Rebuild all four Flutter flavors.
4. Test signup flows against live Supabase:
   - Student under 18
   - Student 18+
   - Parent child-linking
   - Teacher approval pending
   - Counselor approval pending
   - School admin approval pending
5. Add admin approval UI for school/platform administrators.
6. Prepare production Android signing configs.
