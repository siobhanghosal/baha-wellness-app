# Proposed API Endpoints

## Identity

| Method | Path | Purpose |
|---|---|---|
| POST | /auth/login | authenticate user |
| POST | /auth/logout | revoke session |
| POST | /auth/refresh | refresh session |
| GET | /me | fetch role and entitlement context |

## Consent

| Method | Path | Purpose |
|---|---|---|
| GET | /consent/current | fetch active consent state |
| POST | /consent/parent | create guardian consent record |
| POST | /consent/self | create self-consent record |
| POST | /consent/tiers | save privacy tier agreement |
| POST | /consent/withdraw | request consent withdrawal |

## Student Wellbeing

| Method | Path | Purpose |
|---|---|---|
| GET | /student/home | fetch home aggregates and next actions |
| POST | /student/check-ins | submit weekly or optional daily check-in |
| GET | /student/trends | fetch private trend dashboard |
| GET | /student/profile-summary | fetch plain-language memory summary |
| POST | /student/help-request | create support request |

## Learning

| Method | Path | Purpose |
|---|---|---|
| GET | /learning/modules | list role-filtered modules |
| GET | /learning/modules/{id} | fetch module detail |
| POST | /learning/modules/{id}/progress | save progress |
| POST | /learning/modules/{id}/quiz | submit formative quiz or reflection |

## Chatbot

| Method | Path | Purpose |
|---|---|---|
| POST | /chatbot/messages | send prompt and receive grounded response |
| GET | /chatbot/safe-questions | list Safe Questions |
| POST | /chatbot/profile-opt-out | toggle memory/profile building |

## Games

| Method | Path | Purpose |
|---|---|---|
| GET | /games/catalog | list available games |
| POST | /games/sessions | start or resume game session |
| POST | /games/sessions/{id}/events | append telemetry or milestones |
| POST | /games/time-cap/ack | acknowledge advisory limit |

## Parent

| Method | Path | Purpose |
|---|---|---|
| GET | /parent/summary | fetch current weekly summary |
| GET | /parent/conversation-guides | list guides by theme |

## Teacher

| Method | Path | Purpose |
|---|---|---|
| GET | /teacher/class-trends | fetch anonymized weekly dashboard |
| POST | /teacher/pastoral-flags | submit pastoral signal |
| POST | /teacher/referrals | create referral |

## BAHA

| Method | Path | Purpose |
|---|---|---|
| GET | /baha/queue | fetch operational support queue |
| GET | /baha/cases/{id} | fetch case detail |
| POST | /baha/cases/{id}/events | append action log event |
| GET | /baha/content | fetch content library |
| POST | /baha/content | create or update content |
| POST | /baha/thresholds | save threshold configuration |
| GET | /baha/analytics | fetch aggregate dashboard |
| GET | /baha/audit | fetch audit records |
