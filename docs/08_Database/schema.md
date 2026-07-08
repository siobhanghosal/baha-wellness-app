# Database Schema

## Core Entity Groups

### Identity and Access

- users
- roles
- schools
- user_role_assignments
- guardian_links
- staff_scope_assignments

### Consent and Policy

- consent_documents
- consent_records
- assent_records
- privacy_tier_records
- override_events

### Student Wellbeing

- student_profiles
- check_in_sessions
- check_in_responses
- trend_snapshots
- mood_vocabulary_progress
- challenge_instances
- badge_awards

### Learning and Content

- content_items
- content_revisions
- content_tags
- module_progress
- quiz_attempts
- safe_question_items

### Chatbot and Games

- chatbot_sessions
- chatbot_messages
- chatbot_profile_summaries
- game_sessions
- game_signal_snapshots

### Escalation and Operations

- pastoral_flags
- support_cases
- case_events
- case_assignments
- notification_events
- audit_events

## Retention-Sensitive Tables

- check_in_responses
- chatbot_messages
- support_cases
- case_events
- consent_records
- audit_events

## Partitioning Guidance

- partition high-volume events by month or quarter
- include school and cohort keys for analytics rollups
- separate content metadata from asset storage
