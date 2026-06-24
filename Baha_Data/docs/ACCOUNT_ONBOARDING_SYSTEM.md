# BAHA Account Onboarding System

## Purpose

The account onboarding system extends the existing Supabase Auth implementation. Passwords and sessions remain owned by Supabase Auth. The BAHA backend stores role-specific profile, consent, approval, and audit metadata in Supabase PostgreSQL.

## Supported Roles

- `student`
- `parent`
- `teacher`
- `counselor`
- `school_admin`
- `admin` / `platform_admin`

Platform administrators do not have public signup. They must be created by an existing platform administrator through a controlled admin process.

## Signup Flows

### Student

Fields:

- Full name
- Age
- Gender
- Grade
- School
- Email
- Password

Flow:

1. Flutter creates the Supabase Auth user.
2. User metadata includes `role=student`, `age`, and normalized `age_group`.
3. Backend `/auth/signup-profile` creates or updates `profiles`.
4. Students under 18 get `consent_status=pending`.
5. Students 18+ get self-consent behavior through age-group routing.

### Parent / Guardian

Fields:

- Full name
- Email
- Mobile number
- Relationship to student
- Password

Flow:

1. Flutter creates the Supabase Auth user.
2. Backend creates `profiles`, `guardians`, and `parents` shadow records.
3. Parent signs in and links a child through `/auth/parent/link-child`.
4. Parent consent decisions are written through `/auth/consent`.

### Teacher

Fields:

- Full name
- School email
- Employee ID
- School
- Department
- Password

Flow:

1. Flutter creates the Supabase Auth user.
2. Backend creates `profiles` and `teachers`.
3. Backend creates an `approval_requests` row.
4. Account remains `approval_status=pending` until reviewed by a school admin.

### Counselor

Fields:

- Full name
- Professional email
- Organization
- License / registration number
- Password

Flow:

1. Flutter creates the Supabase Auth user.
2. Backend creates `profiles` and counselor metadata.
3. Backend creates an `approval_requests` row.
4. Account remains `approval_status=pending` until reviewed by a platform admin.

### School Admin

Fields:

- Full name
- School name
- School email
- Designation
- Password

Flow:

1. Flutter creates the Supabase Auth user.
2. Backend creates `profiles`, `admins`, and `school_admins`.
3. Backend creates an `approval_requests` row.
4. Account remains `approval_status=pending` until reviewed by a platform admin.

## Database Migration

Migration:

- `supabase/migrations/20260624131500_onboarding_account_creation.sql`

Adds:

- Extended `profiles` metadata columns.
- `parents`
- `school_admins`
- `approval_requests`
- `guardian_student_links` compatibility view over `student_guardian_links`.
- RLS policies for parent, school admin, and approval workflow data.
- Trigger-compatible `ensure_role_shadow_records` support for parent and school admin records.

## Backend Endpoints

- `POST /auth/signup-profile`
- `GET /auth/onboarding-state`
- `POST /auth/parent/link-child`
- `POST /auth/consent`
- `GET /auth/approval-requests`
- `POST /auth/approval-requests/{request_id}/decision`

All endpoints require Supabase JWT authentication. Approval endpoints require platform admin or school admin roles.

## Flutter Screens

Implemented in:

- `baha-wellness-mobile/lib/src/features/auth/presentation/signup_screens.dart`

Screens:

- Role selection
- Student signup
- Parent signup
- Teacher signup
- Counselor signup
- School admin signup
- Email verification
- Consent pending
- Approval pending
- Account linked
- Child linking
- Profile completion

## Route Guards

Implemented in:

- `baha-wellness-mobile/lib/src/core/routing/app_router.dart`

Rules:

- Unauthenticated users can access login, signup, verification, consent pending, and approval pending screens.
- Students with `consent_status=pending` are held at the consent pending screen.
- Teachers, counselors, and school admins with `approval_status=pending` are held at the approval pending screen.
- Dedicated apps still reject accounts for the wrong role.

## Security Notes

- Passwords are never stored in BAHA tables.
- Supabase Auth owns password hashing, refresh tokens, and sessions.
- Backend APIs validate Supabase JWTs.
- RLS is enabled for all new user workflow tables.
- Audit events are recorded for signup, consent updates, approval updates, and child linking workflows.

## Deployment Notes

Apply migrations through the Supabase CLI before enabling the new signup screens against production:

```bash
supabase db push
```

Then redeploy the FastAPI service on Render so the new endpoints are available to the Flutter apps.
