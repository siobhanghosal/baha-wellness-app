# Repositories

## Repository Modules

- AuthRepository
- ConsentRepository
- StudentWellbeingRepository
- LearningRepository
- ChatbotRepository
- GameRepository
- ParentRepository
- TeacherRepository
- BahaOpsRepository
- NotificationRepository
- AnalyticsRepository

## Rules

- repositories expose domain-safe methods rather than raw transport details
- projection filtering for privacy-sensitive payloads should happen server-side, not only client-side
- offline-capable repositories own merge and retry logic
