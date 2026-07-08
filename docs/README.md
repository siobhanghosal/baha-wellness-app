# BAHA Wellness Companion Architecture Repository

This repository transforms the BAHA Wellness Companion PRD into an implementation-oriented architecture pack for product, design, engineering, QA, data, and clinical governance teams.

## Repository Scope

- Four separate Flutter applications sharing one backend:
  - Student App
  - Parent App
  - Teacher App
  - BAHA Counselor/Admin App
- Shared platform services for:
  - authentication and role enforcement
  - consent and privacy-tier enforcement
  - content management and learning delivery
  - chatbot retrieval and response governance
  - monitoring, escalation, and case management
  - analytics, notifications, and auditability

## Reading Order

1. [00_Product_Overview.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/00_Product_Overview.md)
2. [01_Information_Architecture.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/01_Information_Architecture.md)
3. [02_Master_User_Journey.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/02_Master_User_Journey.md)
4. Role-specific app folders:
   - [03_Student_App/README.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/03_Student_App/README.md)
   - [04_Parent_App/README.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/04_Parent_App/README.md)
   - [05_Teacher_App/README.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/05_Teacher_App/README.md)
   - [06_BAHA_App/README.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/06_BAHA_App/README.md)
5. Shared platform:
   - [07_Backend/architecture.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/07_Backend/architecture.md)
   - [08_Database/schema.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/08_Database/schema.md)
   - [11_API/endpoints.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/11_API/endpoints.md)
   - [12_Flutter/routing.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/12_Flutter/routing.md)

## Product Boundaries

- Student experience is private by default and may not expose clinical diagnosis, risk scores, or surveillance patterns.
- Parent experience is summary-based and consent-gated.
- Teacher experience is anonymized at class level except where safeguarding protocols create explicit access.
- BAHA experience is the only surface with operational case management, threshold management, and content governance.
- High-risk escalation remains human-owned and human-reviewed at all times.

## Architecture Principles

- Privacy by default
- Support before crisis
- Separate stakeholder surfaces, shared backend contracts
- Android-first delivery, iOS after pilot hardening
- Rule-based monitoring, not AI diagnosis
- Content-grounded chatbot with BAHA review
- Modular Flutter clients and modular FastAPI services
- Auditable consent, content, escalation, and access history

## Deliverables Included

- information architecture
- user journeys
- navigation graphs
- screen inventories
- screen flows
- state diagrams
- edge cases
- backend architecture
- API contract proposals
- database model
- component hierarchy
- design system guidance
- Flutter module architecture
