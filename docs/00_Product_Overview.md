# Product Overview

## Product Identity

- Product: BAHA Wellness Companion
- Model: adolescent-first digital wellness ecosystem
- Clinical partner: Bangalore Adolescent Health Academy (BAHA)
- Delivery target: Android-first Flutter multi-app suite
- Future target: iOS parity after Android pilot hardening

## Core Problem

The product exists to provide Indian adolescents with a private, trusted, repeat-usage support channel for self-awareness, safe learning, and human-routed support before problems escalate into adult-visible crises.

## Primary Role Surfaces

| Role | Surface | Primary Jobs | Explicit Limits |
|---|---|---|---|
| Student | Dedicated Student App | private check-ins, trends, BAHA Buddy, learning, games, help | no diagnosis, no surveillance, no public ranking |
| Parent/Guardian | Dedicated Parent App | consent, weekly summaries, conversation support, parent education | no raw check-in answers, no diary access, no live tracking |
| Teacher/Counselor | Dedicated Teacher App | class trends, pastoral input, referrals, safeguarding learning | no unrestricted individual data access |
| BAHA/Counselor/Admin | Dedicated BAHA App | support queue, case management, content review, threshold config, analytics | minimum-necessary access only |

## Student Age Segmentation

| Age Band | UX Goal | Interaction Character |
|---|---|---|
| 9-13 | comprehension and safety | simpler language, guided patterns, softer interactions |
| 14-16 | identity and reflection | richer reflection prompts, stronger self-discovery framing |
| 17-19 | autonomy and self-direction | denser insights, stronger consent and control messaging |

## Platform Goals

### Must Deliver

- weekly student check-ins tied to personal trends
- BAHA-grounded chatbot and Safe Questions library
- learning modules for students, parents, and teachers
- insight-generating games with time governance
- consent-gated parent summaries
- teacher pastoral signal capture
- BAHA support queue and case management
- analytics, audit, notification, and content workflows

### Must Not Become

- an AI diagnostic engine
- a passive surveillance tool
- an unowned crisis escalation system
- a public social product without moderation ownership
- a public app-store wellness product before governance hardening

## Release Structure

| Release | Scope |
|---|---|
| R1 | Android functional launch across all four apps and shared backend |
| R1.1 | pilot hardening, threshold calibration, performance and QA stabilization |
| R2 | iOS parity and broader rollout support |
| R3 | research extensions such as passive sensing, wearables, or AI risk modeling only after ethics approval |

## Shared Service Domains

- identity and authentication
- consent and privacy tier management
- wellness check-in capture and trend generation
- learning content catalog and delivery
- BAHA Safe Questions library and chatbot retrieval
- game telemetry and behavioral signal aggregation
- escalation workflow and support queue
- analytics and audit pipelines
- notification orchestration

## Key Governance Rules

- no student data collection before privacy acknowledgement and consent routing complete
- no parent access beyond approved privacy tiers
- no teacher access to raw student wellbeing data
- no high-risk threshold activation without named human responder
- no chatbot sensitive-domain response outside BAHA-approved corpus
- no automatic crisis management without human-in-the-loop review
