# BAHA Flutter UI to Backend Connection Map

This file lists every backend connection the Flutter frontend will need, where in the UI it should be used, and the exact endpoint paths.

It is written for the current UI workspace:

- [app_router.dart](/Users/solomonkaruppiah/Desktop/Baha_Data/ui_prototype_connected/lib/navigation/app_router.dart)
- [auth_screens.dart](/Users/solomonkaruppiah/Desktop/Baha_Data/ui_prototype_connected/lib/screens/auth/auth_screens.dart)
- [student_shell.dart](/Users/solomonkaruppiah/Desktop/Baha_Data/ui_prototype_connected/lib/screens/student/student_shell.dart)
- [parent_shell.dart](/Users/solomonkaruppiah/Desktop/Baha_Data/ui_prototype_connected/lib/screens/parent/parent_shell.dart)
- [teacher_shell.dart](/Users/solomonkaruppiah/Desktop/Baha_Data/ui_prototype_connected/lib/screens/teacher/teacher_shell.dart)
- [admin_shell.dart](/Users/solomonkaruppiah/Desktop/Baha_Data/ui_prototype_connected/lib/screens/admin/admin_shell.dart)
- [detail_screen.dart](/Users/solomonkaruppiah/Desktop/Baha_Data/ui_prototype_connected/lib/screens/shared/detail_screen.dart)

It is based on the backend handoff documents:

- [MOBILE_API_SURFACES.md](/Users/solomonkaruppiah/Desktop/Baha_Data/baha-wellness-app-sudharshan-latest/Baha_Data/docs/MOBILE_API_SURFACES.md)
- [BACKEND_HANDOFF_FOR_FLUTTER.md](/Users/solomonkaruppiah/Desktop/Baha_Data/baha-wellness-app-sudharshan-latest/Baha_Data/docs/BACKEND_HANDOFF_FOR_FLUTTER.md)
- [SCREEN_API_MATRIX.md](/Users/solomonkaruppiah/Desktop/Baha_Data/baha-wellness-app-sudharshan-latest/Baha_Data/docs/SCREEN_API_MATRIX.md)

## 1. Base URLs

Use one base URL per runtime environment.

### Local Android emulator

```text
http://10.0.2.2:8000
```

### Local physical phone on same Wi-Fi

```text
http://<YOUR_LAN_IP>:8000
```

Example:

```text
http://192.168.1.127:8000
```

### Hosted deployment

Use your Render API root when live hosting is enabled.

Format:

```text
https://<your-render-service>.onrender.com
```

If your earlier Render service is still the intended backend:

```text
https://baha-wellness-app.onrender.com
```

## 2. Authentication / Identity Headers

### Local development mode

Use one of these headers until full hosted auth is active:

```text
X-BAHA-User-Id
X-BAHA-External-Auth-Id
```

Optional local onboarding header:

```text
X-BAHA-Auth-Email
```

### Hosted production mode

Use:

```text
Authorization: Bearer <supabase_access_token>
```

## 3. Recommended Flutter API Clients

Recommended service classes and their purpose:

- `AuthApi`
- `IdentityApi`
- `SupportApi`
- `ContentApi`
- `StudentApi`
- `ParentApi`
- `TeacherApi`
- `ChatApi`
- `CounselorApi`

Recommended file layout later:

```text
lib/services/api/auth_api.dart
lib/services/api/identity_api.dart
lib/services/api/support_api.dart
lib/services/api/content_api.dart
lib/services/api/student_api.dart
lib/services/api/parent_api.dart
lib/services/api/teacher_api.dart
lib/services/api/chat_api.dart
lib/services/api/counselor_api.dart
```

## 4. Shared Connections Needed Across All Apps

| Flutter connection name | Method | Exact endpoint path | Full URL pattern | Where to connect in UI | Purpose |
| --- | --- | --- | --- | --- | --- |
| `AuthApi.getOnboardingState()` | `GET` | `/auth/onboarding-state` | `<BASE_URL>/auth/onboarding-state` | Splash, login handoff, onboarding router, blocked-state routing | Decide next app step |
| `AuthApi.bootstrapAccount()` | `POST` | `/auth/bootstrap` | `<BASE_URL>/auth/bootstrap` | Signup completion, onboarding form submit | Create/update BAHA-side profile |
| `AuthApi.getAuthenticatedAccount()` | `GET` | `/auth/me` | `<BASE_URL>/auth/me` | Post-login account resolution | Fetch account/role/onboarding state |
| `IdentityApi.getActiveActor()` | `GET` | `/mobile/me` | `<BASE_URL>/mobile/me` | After auth routing, all dashboards | Resolve display name, primary role, audience, active profile |
| `SupportApi.getSupportContacts()` | `GET` | `/mobile/support-contacts` | `<BASE_URL>/mobile/support-contacts` | Student help, parent settings, BAHA crisis contacts | Show support and emergency contacts |
| `ContentApi.getFeed()` | `GET` | `/mobile/content/feed` | `<BASE_URL>/mobile/content/feed` | Student learn, parent resources, teacher resources, BAHA content | Fetch role-safe content feed |
| `ContentApi.getContentDetail(contentItemId)` | `GET` | `/mobile/content/{content_item_id}` | `<BASE_URL>/mobile/content/{content_item_id}` | All resource/module/content detail screens | Open one content item |

## 5. Auth And Onboarding Connections

### 5.1 Shared startup flow

These screens need backend connections:

- [splash_screen.dart](/Users/solomonkaruppiah/Desktop/Baha_Data/ui_prototype_connected/lib/screens/shared/splash_screen.dart)
- [auth_screens.dart](/Users/solomonkaruppiah/Desktop/Baha_Data/ui_prototype_connected/lib/screens/auth/auth_screens.dart)

Required connections:

| UI stage | Flutter connection name | Method | Endpoint |
| --- | --- | --- | --- |
| Session restore | `AuthApi.getOnboardingState()` | `GET` | `/auth/onboarding-state` |
| Account bootstrap submit | `AuthApi.bootstrapAccount()` | `POST` | `/auth/bootstrap` |
| Post-bootstrap route resolution | `AuthApi.getOnboardingState()` | `GET` | `/auth/onboarding-state` |
| Actor role resolution | `AuthApi.getAuthenticatedAccount()` | `GET` | `/auth/me` |
| Actor audience resolution | `IdentityApi.getActiveActor()` | `GET` | `/mobile/me` |

### 5.2 Parent consent onboarding

These onboarding flows need backend connections:

- Student linking
- Platform participation consent
- Summary sharing consent

Required connections:

| Flutter connection name | Method | Endpoint | Used in |
| --- | --- | --- | --- |
| `AuthApi.linkStudentToGuardian()` | `POST` | `/auth/guardian/link-student` | Parent linking flow |
| `AuthApi.grantPlatformParticipationConsent()` | `POST` | `/auth/guardian/consent/platform-participation` | Parent participation approval flow |
| `AuthApi.getParentSummaryConsent(studentProfileId)` | `GET` | `/auth/guardian/consent/parent-summary-sharing/{student_profile_id}` | Parent summary consent screen |
| `AuthApi.updateParentSummaryConsent()` | `POST` | `/auth/guardian/consent/parent-summary-sharing` | Parent summary consent save action |

### 5.3 Approval workflows

These are for teacher and BAHA/counselor approval flows.

| Flutter connection name | Method | Endpoint | Used in |
| --- | --- | --- | --- |
| `AuthApi.getApprovalRequests()` | `GET` | `/auth/approval-requests` | BAHA approval queue |
| `AuthApi.submitApprovalDecision(requestId)` | `POST` | `/auth/approval-requests/{request_id}/decision` | BAHA approval decision screen |

## 6. Student App Connections

Primary UI files:

- [student_shell.dart](/Users/solomonkaruppiah/Desktop/Baha_Data/ui_prototype_connected/lib/screens/student/student_shell.dart)
- [detail_screen.dart](/Users/solomonkaruppiah/Desktop/Baha_Data/ui_prototype_connected/lib/screens/shared/detail_screen.dart)

### 6.1 Student dashboard

| Flutter connection name | Method | Endpoint | Full URL pattern | UI use |
| --- | --- | --- | --- | --- |
| `IdentityApi.getActiveActor()` | `GET` | `/mobile/me` | `<BASE_URL>/mobile/me` | Home header, student identity |
| `StudentApi.getLatestWeeklySummary()` | `GET` | `/mobile/student/weekly-summary/latest` | `<BASE_URL>/mobile/student/weekly-summary/latest` | Dashboard summary and trend headline |
| `StudentApi.getCheckins()` | `GET` | `/mobile/student/checkins` | `<BASE_URL>/mobile/student/checkins` | Recent check-in state on dashboard |

### 6.2 Student check-ins

| Flutter connection name | Method | Endpoint | Full URL pattern | UI use |
| --- | --- | --- | --- | --- |
| `StudentApi.getCheckinTemplates()` | `GET` | `/mobile/student/checkin-templates` | `<BASE_URL>/mobile/student/checkin-templates` | Check-in list screen |
| `StudentApi.getCheckinTemplate(templateId)` | `GET` | `/mobile/student/checkin-templates/{template_id}` | `<BASE_URL>/mobile/student/checkin-templates/{template_id}` | Check-in detail form |
| `StudentApi.getCheckins()` | `GET` | `/mobile/student/checkins` | `<BASE_URL>/mobile/student/checkins` | Recent submissions |
| `StudentApi.getCheckinResponse(responseSetId)` | `GET` | `/mobile/student/checkins/{response_set_id}` | `<BASE_URL>/mobile/student/checkins/{response_set_id}` | Review previous submission |
| `StudentApi.submitCheckin()` | `POST` | `/mobile/student/checkins` | `<BASE_URL>/mobile/student/checkins` | Submit answers |

### 6.3 Student learning

| Flutter connection name | Method | Endpoint | Full URL pattern | UI use |
| --- | --- | --- | --- | --- |
| `ContentApi.getFeed()` | `GET` | `/mobile/content/feed` | `<BASE_URL>/mobile/content/feed` | Student learn feed |
| `StudentApi.getModules()` | `GET` | `/mobile/student/modules` | `<BASE_URL>/mobile/student/modules` | Student module listing |
| `ContentApi.getContentDetail(contentItemId)` | `GET` | `/mobile/content/{content_item_id}` | `<BASE_URL>/mobile/content/{content_item_id}` | Module content detail |
| `StudentApi.updateModuleProgress(moduleId)` | `POST` | `/mobile/student/modules/{module_id}/progress` | `<BASE_URL>/mobile/student/modules/{module_id}/progress` | Save progress |

### 6.4 Student Buddy chat

| Flutter connection name | Method | Endpoint | Full URL pattern | UI use |
| --- | --- | --- | --- | --- |
| `ChatApi.getSessions()` | `GET` | `/mobile/chat/sessions` | `<BASE_URL>/mobile/chat/sessions` | Buddy session list |
| `ChatApi.createSession()` | `POST` | `/mobile/chat/sessions` | `<BASE_URL>/mobile/chat/sessions` | Start new Buddy session |
| `ChatApi.getMessages(sessionId)` | `GET` | `/mobile/chat/sessions/{session_id}/messages` | `<BASE_URL>/mobile/chat/sessions/{session_id}/messages` | Open chat thread |
| `ChatApi.sendMessage(sessionId)` | `POST` | `/mobile/chat/sessions/{session_id}/messages` | `<BASE_URL>/mobile/chat/sessions/{session_id}/messages` | Send student message |

### 6.5 Student help and support

| Flutter connection name | Method | Endpoint | Full URL pattern | UI use |
| --- | --- | --- | --- | --- |
| `SupportApi.getSupportContacts()` | `GET` | `/mobile/support-contacts` | `<BASE_URL>/mobile/support-contacts` | SOS/help screen |
| `StudentApi.createHelpRequest()` | `POST` | `/mobile/student/help-requests` | `<BASE_URL>/mobile/student/help-requests` | Submit support request |

### 6.6 Student profile and settings

| Flutter connection name | Method | Endpoint | Full URL pattern | UI use |
| --- | --- | --- | --- | --- |
| `IdentityApi.getActiveActor()` | `GET` | `/mobile/me` | `<BASE_URL>/mobile/me` | Profile header and role data |
| `AuthApi.getOnboardingState()` | `GET` | `/auth/onboarding-state` | `<BASE_URL>/auth/onboarding-state` | Consent / privacy status summary |

### 6.7 Student connections still not available in backend

These frontend pages must stay local or mocked until backend exposes them:

| UI area | Missing endpoint needed later |
| --- | --- |
| Games Hub runtime | No current mobile game endpoints |
| Trend history | No dedicated historical trend endpoint yet |
| Rich profile editing | No dedicated profile-update endpoint in current mobile contract |

## 7. Parent App Connections

Primary UI files:

- [parent_shell.dart](/Users/solomonkaruppiah/Desktop/Baha_Data/ui_prototype_connected/lib/screens/parent/parent_shell.dart)
- [detail_screen.dart](/Users/solomonkaruppiah/Desktop/Baha_Data/ui_prototype_connected/lib/screens/shared/detail_screen.dart)

### 7.1 Parent home and linked child views

| Flutter connection name | Method | Endpoint | Full URL pattern | UI use |
| --- | --- | --- | --- | --- |
| `ParentApi.getLinkedStudents()` | `GET` | `/mobile/parent/students` | `<BASE_URL>/mobile/parent/students` | Parent home, linked students list |
| `ParentApi.getLatestWeeklySummary(studentProfileId)` | `GET` | `/mobile/parent/students/{student_profile_id}/weekly-summary/latest` | `<BASE_URL>/mobile/parent/students/{student_profile_id}/weekly-summary/latest` | Parent summary card and summary detail |

### 7.2 Parent consent and participation flows

| Flutter connection name | Method | Endpoint | Full URL pattern | UI use |
| --- | --- | --- | --- | --- |
| `AuthApi.linkStudentToGuardian()` | `POST` | `/auth/guardian/link-student` | `<BASE_URL>/auth/guardian/link-student` | Link child account |
| `AuthApi.getParentSummaryConsent(studentProfileId)` | `GET` | `/auth/guardian/consent/parent-summary-sharing/{student_profile_id}` | `<BASE_URL>/auth/guardian/consent/parent-summary-sharing/{student_profile_id}` | Summary sharing screen |
| `AuthApi.updateParentSummaryConsent()` | `POST` | `/auth/guardian/consent/parent-summary-sharing` | `<BASE_URL>/auth/guardian/consent/parent-summary-sharing` | Save summary sharing decision |
| `AuthApi.grantPlatformParticipationConsent()` | `POST` | `/auth/guardian/consent/platform-participation` | `<BASE_URL>/auth/guardian/consent/platform-participation` | Minor participation consent |

### 7.3 Parent resources and settings

| Flutter connection name | Method | Endpoint | Full URL pattern | UI use |
| --- | --- | --- | --- | --- |
| `ContentApi.getFeed(contentType: "conversation_guide")` | `GET` | `/mobile/content/feed?content_type=conversation_guide` | `<BASE_URL>/mobile/content/feed?content_type=conversation_guide` | Parent resources feed |
| `ContentApi.getContentDetail(contentItemId)` | `GET` | `/mobile/content/{content_item_id}` | `<BASE_URL>/mobile/content/{content_item_id}` | Parent resource detail |
| `SupportApi.getSupportContacts()` | `GET` | `/mobile/support-contacts` | `<BASE_URL>/mobile/support-contacts` | Parent settings / support section |
| `AuthApi.getOnboardingState()` | `GET` | `/auth/onboarding-state` | `<BASE_URL>/auth/onboarding-state` | Parent settings and linking status |

### 7.4 Parent connections still not available in backend

| UI area | Missing endpoint needed later |
| --- | --- |
| Parent notifications center | No current notifications endpoint |
| Rich privacy-tier editor | No dedicated final mobile mutation surface documented |

## 8. Teacher App Connections

Primary UI files:

- [teacher_shell.dart](/Users/solomonkaruppiah/Desktop/Baha_Data/ui_prototype_connected/lib/screens/teacher/teacher_shell.dart)
- [detail_screen.dart](/Users/solomonkaruppiah/Desktop/Baha_Data/ui_prototype_connected/lib/screens/shared/detail_screen.dart)

### 8.1 Teacher classes and reports

| Flutter connection name | Method | Endpoint | Full URL pattern | UI use |
| --- | --- | --- | --- | --- |
| `TeacherApi.getClasses()` | `GET` | `/mobile/teacher/classes` | `<BASE_URL>/mobile/teacher/classes` | Class list |
| `TeacherApi.getClassStudents(classId)` | `GET` | `/mobile/teacher/classes/{class_id}/students` | `<BASE_URL>/mobile/teacher/classes/{class_id}/students` | Students list within class |
| `TeacherApi.getClassCohortSummary(classId)` | `GET` | `/mobile/teacher/classes/{class_id}/cohort-summary/latest` | `<BASE_URL>/mobile/teacher/classes/{class_id}/cohort-summary/latest` | Class summary / reports |

### 8.2 Teacher pastoral workflow

| Flutter connection name | Method | Endpoint | Full URL pattern | UI use |
| --- | --- | --- | --- | --- |
| `TeacherApi.submitPastoralFlag()` | `POST` | `/mobile/teacher/pastoral-flags` | `<BASE_URL>/mobile/teacher/pastoral-flags` | Pastoral flag form |

### 8.3 Teacher resources and settings

| Flutter connection name | Method | Endpoint | Full URL pattern | UI use |
| --- | --- | --- | --- | --- |
| `ContentApi.getTeacherFeed()` | `GET` | `/mobile/content/feed?audience_app=teacher` | `<BASE_URL>/mobile/content/feed?audience_app=teacher` | Teacher resources feed |
| `ContentApi.getTeacherContentDetail(contentItemId)` | `GET` | `/mobile/content/{content_item_id}?audience_app=teacher` | `<BASE_URL>/mobile/content/{content_item_id}?audience_app=teacher` | Teacher resource detail |
| `AuthApi.getOnboardingState()` | `GET` | `/auth/onboarding-state` | `<BASE_URL>/auth/onboarding-state` | Approval state / teacher status |

### 8.4 Teacher connections still not available in backend

| UI area | Missing endpoint needed later |
| --- | --- |
| Referral workflow | No referral workflow endpoint yet |
| Teacher notifications | No teacher notifications endpoint yet |

## 9. BAHA / Counselor App Connections

Primary UI files:

- [admin_shell.dart](/Users/solomonkaruppiah/Desktop/Baha_Data/ui_prototype_connected/lib/screens/admin/admin_shell.dart)
- [detail_screen.dart](/Users/solomonkaruppiah/Desktop/Baha_Data/ui_prototype_connected/lib/screens/shared/detail_screen.dart)

### 9.1 Operations dashboard and queue

| Flutter connection name | Method | Endpoint | Full URL pattern | UI use |
| --- | --- | --- | --- | --- |
| `CounselorApi.getDashboardLatest()` | `GET` | `/mobile/counselor/dashboard/latest` | `<BASE_URL>/mobile/counselor/dashboard/latest` | BAHA dashboard metrics |
| `CounselorApi.getQueue()` | `GET` | `/mobile/counselor/queue` | `<BASE_URL>/mobile/counselor/queue` | Support queue |

### 9.2 Cases and notes

| Flutter connection name | Method | Endpoint | Full URL pattern | UI use |
| --- | --- | --- | --- | --- |
| `CounselorApi.getCaseDetail(caseId)` | `GET` | `/mobile/counselor/cases/{case_id}` | `<BASE_URL>/mobile/counselor/cases/{case_id}` | Case detail |
| `CounselorApi.addCaseNote(caseId)` | `POST` | `/mobile/counselor/cases/{case_id}/notes` | `<BASE_URL>/mobile/counselor/cases/{case_id}/notes` | Add case note |

### 9.3 Approval and review

| Flutter connection name | Method | Endpoint | Full URL pattern | UI use |
| --- | --- | --- | --- | --- |
| `AuthApi.getApprovalRequests()` | `GET` | `/auth/approval-requests` | `<BASE_URL>/auth/approval-requests` | Approval queue |
| `AuthApi.submitApprovalDecision(requestId)` | `POST` | `/auth/approval-requests/{request_id}/decision` | `<BASE_URL>/auth/approval-requests/{request_id}/decision` | Approval decision |

### 9.4 Content and crisis references

| Flutter connection name | Method | Endpoint | Full URL pattern | UI use |
| --- | --- | --- | --- | --- |
| `ContentApi.getCounselorFeed()` | `GET` | `/mobile/content/feed?audience_app=counselor` | `<BASE_URL>/mobile/content/feed?audience_app=counselor` | Operational content feed |
| `ContentApi.getCounselorContentDetail(contentItemId)` | `GET` | `/mobile/content/{content_item_id}?audience_app=counselor` | `<BASE_URL>/mobile/content/{content_item_id}?audience_app=counselor` | Operational content detail |
| `SupportApi.getSupportContacts()` | `GET` | `/mobile/support-contacts` | `<BASE_URL>/mobile/support-contacts` | Expert routing and crisis contacts |

### 9.5 BAHA connections still not available in backend

| UI area | Missing endpoint needed later |
| --- | --- |
| Content review workflow mutations | No content review mutation endpoints yet |
| Threshold configuration | No threshold configuration endpoints yet |
| Full case assignment workflow | Not exposed as current mobile workflow |

## 10. Exact Endpoint Inventory

These are the exact currently documented backend routes the Flutter frontend can connect to now.

### Auth / onboarding

- `POST /auth/bootstrap`
- `GET /auth/onboarding-state`
- `GET /auth/me`
- `POST /auth/guardian/link-student`
- `POST /auth/guardian/consent/platform-participation`
- `GET /auth/guardian/consent/parent-summary-sharing/{student_profile_id}`
- `POST /auth/guardian/consent/parent-summary-sharing`
- `GET /auth/approval-requests`
- `POST /auth/approval-requests/{request_id}/decision`

### Shared mobile

- `GET /mobile/me`
- `GET /mobile/support-contacts`
- `GET /mobile/content/feed`
- `GET /mobile/content/{content_item_id}`
- `GET /mobile/chat/sessions`
- `POST /mobile/chat/sessions`
- `GET /mobile/chat/sessions/{session_id}/messages`
- `POST /mobile/chat/sessions/{session_id}/messages`

### Student mobile

- `GET /mobile/student/weekly-summary/latest`
- `GET /mobile/student/checkin-templates`
- `GET /mobile/student/checkin-templates/{template_id}`
- `GET /mobile/student/checkins`
- `GET /mobile/student/checkins/{response_set_id}`
- `POST /mobile/student/checkins`
- `GET /mobile/student/modules`
- `POST /mobile/student/modules/{module_id}/progress`
- `POST /mobile/student/help-requests`

### Parent mobile

- `GET /mobile/parent/students`
- `GET /mobile/parent/students/{student_profile_id}/weekly-summary/latest`

### Teacher mobile

- `GET /mobile/teacher/classes`
- `GET /mobile/teacher/classes/{class_id}/students`
- `GET /mobile/teacher/classes/{class_id}/cohort-summary/latest`
- `POST /mobile/teacher/pastoral-flags`

### BAHA / Counselor mobile

- `GET /mobile/counselor/queue`
- `GET /mobile/counselor/dashboard/latest`
- `GET /mobile/counselor/cases/{case_id}`
- `POST /mobile/counselor/cases/{case_id}/notes`

## 11. What Flutter Must Not Connect To Directly

Flutter should not connect directly to:

- PostgreSQL
- Supabase Postgres tables
- pgvector tables
- internal acquisition/admin pipelines

Flutter should only connect through the backend API.

## 12. Immediate Build Recommendation

If frontend-to-backend wiring begins now, use this order:

1. Shared startup and identity connections
2. Student app connections
3. Parent app connections
4. Teacher app connections
5. BAHA app connections
6. Replace remaining mocked flows only after these APIs are stable

