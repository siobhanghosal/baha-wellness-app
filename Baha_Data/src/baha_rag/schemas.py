from __future__ import annotations

from datetime import date, datetime
from typing import Any, Literal
from uuid import UUID

from pydantic import BaseModel, Field, HttpUrl


Audience = Literal[
    "adolescent", "parent", "teacher", "counselor", "administrator",
    "school", "general", "research", "clinical",
]
Severity = Literal["low", "moderate", "high", "emergency", "unknown"]
EvidenceLevel = Literal["guideline", "government", "systematic_review", "peer_reviewed", "educational", "unknown"]
Perspective = Literal["parent", "teacher", "counselor", "adolescent"]


class ChunkMetadata(BaseModel):
    condition: str | None = None
    topic: str | None = None
    subtopic: str | None = None
    age_group: str = "adolescent"
    gender_group: str = "all"
    audience: Audience = "general"
    severity: Severity = "unknown"
    source: str
    country: str | None = None
    publication_date: date | None = None
    evidence_level: EvidenceLevel = "unknown"
    organization: str
    language: str = "en"


class Citation(BaseModel):
    title: str
    organization: str
    url: str | None = None
    publication_date: date | None = None
    chunk_id: UUID | None = None


class SearchRequest(BaseModel):
    query: str = Field(min_length=3, max_length=1000)
    top_k: int = Field(default=8, ge=1, le=30)
    filters: dict[str, Any] = Field(default_factory=dict)


class SearchResult(BaseModel):
    chunk_id: UUID
    document_id: UUID
    text: str
    metadata: ChunkMetadata
    citations: list[Citation]
    dense_score: float = 0.0
    lexical_score: float = 0.0
    confidence: float = 0.0


class SearchResponse(BaseModel):
    query: str
    top_k: int
    results: list[SearchResult]


class ViewRequest(BaseModel):
    condition: str = Field(min_length=2, max_length=120)
    audience: Perspective = "parent"
    age_group: str = "adolescent"
    gender_group: str = "all"
    top_k: int = Field(default=8, ge=4, le=20)


class EvidenceAnswer(BaseModel):
    perspective: Perspective
    condition: str
    what_it_is: str
    how_to_identify_it: str
    what_to_do: str
    when_to_seek_help: str
    safety_note: str
    evidence_sources: list[Citation]
    confidence: float


class ChatRequest(BaseModel):
    message: str = Field(min_length=3, max_length=1600)
    audience: Perspective = "adolescent"
    top_k: int = Field(default=8, ge=4, le=20)
    filters: dict[str, Any] = Field(default_factory=dict)


class ChatResponse(BaseModel):
    answer: EvidenceAnswer
    retrieved: list[SearchResult]


class ConditionSummary(BaseModel):
    condition: str
    category: str
    topics: list[str]


class ConditionKnowledge(BaseModel):
    condition: str
    definition: str
    symptoms: list[str] = Field(default_factory=list)
    risk_factors: list[str] = Field(default_factory=list)
    protective_factors: list[str] = Field(default_factory=list)
    parent_signs: list[str] = Field(default_factory=list)
    teacher_signs: list[str] = Field(default_factory=list)
    assessment_methods: list[str] = Field(default_factory=list)
    recommended_interventions: list[str] = Field(default_factory=list)
    classroom_support: list[str] = Field(default_factory=list)
    family_support: list[str] = Field(default_factory=list)
    escalation_indicators: list[str] = Field(default_factory=list)
    emergency_indicators: list[str] = Field(default_factory=list)
    approved_resources: list[str] = Field(default_factory=list)
    evidence_sources: list[Citation] = Field(default_factory=list)


class IngestUrlRequest(BaseModel):
    url: HttpUrl
    organization: str
    audience: Audience = "general"
    country: str | None = None
    evidence_level: EvidenceLevel = "unknown"


class IngestResponse(BaseModel):
    document_id: UUID
    url: str
    chunks_created: int
    content_hash: str
    ingested_at: datetime


class AcquisitionDiscoverRequest(BaseModel):
    organization: str | None = None
    include_research: bool = True
    limit_per_topic: int = Field(default=25, ge=1, le=100)


class AcquisitionDownloadRequest(BaseModel):
    limit: int = Field(default=100, ge=1, le=1000)


class ReviewDecisionRequest(BaseModel):
    status: Literal["approved", "rejected", "needs_changes"]
    reviewer: str = Field(min_length=2, max_length=120)
    notes: str | None = None


class AcquisitionJobResponse(BaseModel):
    status: str
    detail: dict[str, Any] = Field(default_factory=dict)


MobileAppAudience = Literal["student", "parent", "teacher", "counselor"]
AuthRequestedRole = Literal["student", "guardian", "teacher", "counselor", "administrator"]
LegalConsentBand = Literal["minor", "adult"]
ApprovalRequestStatus = Literal["pending", "approved", "rejected", "revoked", "not_required"]
PlatformConsentStatus = Literal["pending", "granted", "declined", "withdrawn", "not_required"]
PresentationAgeCohort = Literal["9_12", "13_14", "15_18", "18_plus", "all"]
GuardianType = Literal["parent", "guardian", "caregiver", "other"]
ModuleProgressStatus = Literal["not_started", "in_progress", "completed", "paused", "abandoned"]
ChatSessionType = Literal[
    "general_support",
    "learning_helper",
    "checkin_followup",
    "parent_guidance",
    "teacher_guidance",
    "counselor_support",
    "crisis_triage",
]
SummaryVisibilityScope = Literal["private", "consented_summary", "safeguarding_only"]


class AuthBootstrapRequest(BaseModel):
    role: AuthRequestedRole
    display_name: str = Field(min_length=2, max_length=160)
    email: str | None = Field(default=None, max_length=255)
    phone: str | None = Field(default=None, max_length=40)
    preferred_language: str = Field(default="en", min_length=2, max_length=10)
    school_id: UUID | None = None
    school_name: str | None = Field(default=None, max_length=160)
    age_cohort: PresentationAgeCohort | None = None
    legal_consent_band: LegalConsentBand | None = None
    date_of_birth: date | None = None
    gender: str = Field(default="unspecified", max_length=40)
    guardian_type: GuardianType = "parent"
    staff_code: str | None = Field(default=None, max_length=80)
    metadata: dict[str, Any] = Field(default_factory=dict)


class AuthGuardianLinkStudentRequest(BaseModel):
    student_profile_id: UUID | None = None
    student_code: str | None = Field(default=None, max_length=80)
    relationship_to_student: str = Field(min_length=2, max_length=80)
    is_primary: bool = True
    consent_authority: bool = True


class AuthPlatformParticipationConsentRequest(BaseModel):
    student_profile_id: UUID
    status: Literal["granted", "declined", "withdrawn"] = "granted"


class AuthParentSummaryConsentRequest(BaseModel):
    student_profile_id: UUID
    status: Literal["granted", "declined", "withdrawn"] = "granted"


class AuthApprovalDecisionRequest(BaseModel):
    status: Literal["approved", "rejected", "revoked"]
    reviewer_notes: str | None = Field(default=None, max_length=1000)


class AuthApprovalRequestSummary(BaseModel):
    id: UUID
    user_id: UUID
    requested_role: str
    school_id: UUID | None = None
    school_name: str | None = None
    request_type: str
    status: str
    requested_metadata: dict[str, Any] = Field(default_factory=dict)
    reviewer_user_id: UUID | None = None
    reviewer_name: str | None = None
    reviewer_notes: str | None = None
    requested_at: datetime
    reviewed_at: datetime | None = None
    requested_display_name: str
    requested_email: str | None = None


class AuthOnboardingStateResponse(BaseModel):
    has_baha_user: bool
    identity_match_mode: str
    external_auth_id: str
    user_id: UUID | None = None
    email: str | None = None
    display_name: str | None = None
    account_status: str | None = None
    roles: list[str] = Field(default_factory=list)
    primary_role: str | None = None
    school_id: UUID | None = None
    student_profile_id: UUID | None = None
    guardian_id: UUID | None = None
    teacher_profile_id: UUID | None = None
    student_code: str | None = None
    age_cohort: str | None = None
    legal_consent_band: str | None = None
    approval_status: str
    consent_status: str
    guardian_link_status: str
    linked_student_count: int = 0
    linked_guardian_count: int = 0
    next_step: str
    detail: str | None = None


class AuthParentSummaryConsentResponse(BaseModel):
    consent_type: Literal["parent_summary_sharing"] = "parent_summary_sharing"
    consent_version_id: UUID | None = None
    student_profile_id: UUID
    guardian_id: UUID
    status: Literal["pending", "granted", "declined", "withdrawn"]
    scope: str
    actor_relationship: str | None = None
    granted_at: datetime | None = None
    withdrawn_at: datetime | None = None
    created_at: datetime | None = None


class MobileActorResponse(BaseModel):
    user_id: UUID
    external_auth_id: str | None = None
    display_name: str
    roles: list[str] = Field(default_factory=list)
    primary_role: str
    app_audience: MobileAppAudience
    student_profile_id: UUID | None = None
    guardian_id: UUID | None = None
    teacher_profile_id: UUID | None = None
    age_cohort: str | None = None
    school_id: UUID | None = None


class MobileCheckinTemplateSummary(BaseModel):
    id: UUID
    template_key: str
    title: str
    cadence: str
    age_cohort: str
    question_count: int
    metadata: dict[str, Any] = Field(default_factory=dict)


class MobileCheckinQuestion(BaseModel):
    id: UUID
    question_key: str
    dimension: str
    question_type: str
    prompt: str
    response_config: dict[str, Any] = Field(default_factory=dict)
    is_required: bool
    ordinal: int
    metadata: dict[str, Any] = Field(default_factory=dict)


class MobileCheckinTemplateDetail(BaseModel):
    id: UUID
    template_key: str
    title: str
    cadence: str
    age_cohort: str
    metadata: dict[str, Any] = Field(default_factory=dict)
    questions: list[MobileCheckinQuestion] = Field(default_factory=list)


class StudentWeeklySummaryResponse(BaseModel):
    id: UUID
    student_profile_id: UUID
    week_start: date
    week_end: date
    privacy_tier_applied: str
    summary_status: str
    summary: dict[str, Any] = Field(default_factory=dict)
    source_window: dict[str, Any] = Field(default_factory=dict)
    generation_version: str
    generated_at: datetime


class MobileModuleSummary(BaseModel):
    id: UUID
    content_item_id: UUID
    module_code: str
    title: str
    theme: str
    age_cohort: str
    estimated_minutes: int | None = None
    sort_order: int
    progress_status: ModuleProgressStatus
    completion_percent: float
    current_section_ordinal: int | None = None
    current_step_ordinal: int | None = None
    last_activity_at: datetime | None = None
    module_progress_id: UUID | None = None
    total_sections: int = 0
    total_steps: int = 0


class ModuleProgressUpsertRequest(BaseModel):
    status: ModuleProgressStatus
    completion_percent: float = Field(ge=0, le=100)
    current_section_ordinal: int | None = Field(default=None, ge=1)
    current_step_ordinal: int | None = Field(default=None, ge=1)


class ModuleProgressUpsertResponse(BaseModel):
    id: UUID
    status: ModuleProgressStatus
    completion_percent: float
    current_section_ordinal: int | None = None
    current_step_ordinal: int | None = None
    last_activity_at: datetime | None = None
    updated_at: datetime


class ChatSessionSummary(BaseModel):
    id: UUID
    session_type: ChatSessionType
    status: str
    safety_disposition: str
    started_at: datetime
    ended_at: datetime | None = None
    last_message_at: datetime | None = None
    message_count: int
    summary_visibility_scope: SummaryVisibilityScope


class ChatSessionCreateRequest(BaseModel):
    session_type: ChatSessionType = "general_support"
    summary_visibility_scope: SummaryVisibilityScope = "private"


class MobileLinkedStudentSummary(BaseModel):
    student_profile_id: UUID
    student_name: str
    age_cohort: str | None = None
    relationship_to_student: str
    is_primary: bool
    school_name: str | None = None


class MobileContentSummary(BaseModel):
    id: UUID
    slug: str
    title: str
    content_type: str
    audience_app: str
    age_cohort: str
    theme: str | None = None
    topic: str | None = None
    subtopic: str | None = None
    summary: str | None = None
    version_id: UUID
    version_number: int
    plain_text: str | None = None
    metadata: dict[str, Any] = Field(default_factory=dict)
    published_at: datetime | None = None


class MobileContentDetail(BaseModel):
    id: UUID
    slug: str
    title: str
    content_type: str
    audience_app: str
    age_cohort: str
    theme: str | None = None
    topic: str | None = None
    subtopic: str | None = None
    summary: str | None = None
    version_id: UUID
    version_number: int
    body: dict[str, Any] = Field(default_factory=dict)
    plain_text: str | None = None
    metadata: dict[str, Any] = Field(default_factory=dict)
    published_at: datetime | None = None
    reviewed_by: str | None = None
    reviewed_at: datetime | None = None


class ParentAccessSummary(BaseModel):
    allowed: bool
    mode: str
    visible_tiers: list[str] = Field(default_factory=list)
    reason: str | None = None


class ParentWeeklySummaryResponse(BaseModel):
    id: UUID
    student_profile_id: UUID
    guardian_id: UUID
    week_start: date
    week_end: date
    consent_status: str
    visible_tiers: list[str] = Field(default_factory=list)
    summary: dict[str, Any] = Field(default_factory=dict)
    generated_at: datetime
    access: ParentAccessSummary


class TeacherClassSummary(BaseModel):
    class_id: UUID
    class_code: str | None = None
    label: str
    academic_year: str | None = None
    grade_band: str | None = None
    assignment_type: str
    active_student_count: int


class TeacherClassStudentSummary(BaseModel):
    student_profile_id: UUID
    student_name: str
    age_cohort: str | None = None
    membership_status: str


class TeacherCohortSummaryResponse(BaseModel):
    id: UUID
    school_id: UUID
    class_id: UUID
    week_start: date
    week_end: date
    summary_scope: str
    student_count: int
    anonymized_summary: dict[str, Any] = Field(default_factory=dict)
    generated_at: datetime


class PastoralFlagCreateRequest(BaseModel):
    student_profile_id: UUID
    class_id: UUID | None = None
    flag_type: Literal["attendance_change", "mood_change", "peer_issue", "behavior_change", "academic_stress", "safeguarding", "other"]
    severity: Literal["low", "moderate", "high", "emergency"] = "moderate"
    summary: str = Field(min_length=5, max_length=500)
    details: dict[str, Any] = Field(default_factory=dict)


class PastoralFlagResponse(BaseModel):
    id: UUID
    student_profile_id: UUID
    teacher_profile_id: UUID | None = None
    class_id: UUID | None = None
    flag_type: str
    severity: str
    status: str
    summary: str
    details: dict[str, Any] = Field(default_factory=dict)
    created_at: datetime


class HelpRequestCreateRequest(BaseModel):
    category: Literal["emotional_support", "academic_stress", "peer_issue", "family_issue", "crisis", "other"]
    urgency: Literal["standard", "priority", "urgent", "emergency"] = "standard"
    summary: str = Field(min_length=5, max_length=500)
    details: dict[str, Any] = Field(default_factory=dict)
    visibility_scope: SummaryVisibilityScope = "private"


class HelpRequestResponse(BaseModel):
    id: UUID
    student_profile_id: UUID | None = None
    requested_by_user_id: UUID
    requested_for_user_id: UUID | None = None
    request_channel: str
    category: str
    urgency: str
    status: str
    summary: str
    details: dict[str, Any] = Field(default_factory=dict)
    visibility_scope: str
    created_at: datetime


class MobileSupportContact(BaseModel):
    id: UUID
    school_id: UUID | None = None
    contact_type: str
    audience_app: str
    label: str
    phone: str | None = None
    email: str | None = None
    contact_url: str | None = None
    service_hours: str | None = None
    priority: int
    metadata: dict[str, Any] = Field(default_factory=dict)


class CheckinAnswerInput(BaseModel):
    question_id: UUID
    numeric_value: float | None = None
    text_value: str | None = None
    boolean_value: bool | None = None
    selected_options: list[str] = Field(default_factory=list)
    normalized_value: dict[str, Any] = Field(default_factory=dict)


class CheckinSubmissionRequest(BaseModel):
    template_id: UUID
    source_mode: Literal["scheduled", "manual", "daily_optional", "challenge"] = "manual"
    visibility_scope: SummaryVisibilityScope = "private"
    answers: list[CheckinAnswerInput] = Field(min_length=1)


class StudentCheckinSummary(BaseModel):
    id: UUID
    template_id: UUID
    template_key: str
    title: str
    scheduled_for: datetime | None = None
    submitted_at: datetime | None = None
    status: str
    source_mode: str
    visibility_scope: str
    response_count: int


class StudentCheckinAnswer(BaseModel):
    question_id: UUID
    question_key: str
    prompt: str
    dimension: str
    question_type: str
    numeric_value: float | None = None
    text_value: str | None = None
    boolean_value: bool | None = None
    selected_options: list[str] = Field(default_factory=list)
    normalized_value: dict[str, Any] = Field(default_factory=dict)


class StudentCheckinDetail(BaseModel):
    id: UUID
    template_id: UUID
    template_key: str
    title: str
    scheduled_for: datetime | None = None
    submitted_at: datetime | None = None
    status: str
    source_mode: str
    visibility_scope: str
    answers: list[StudentCheckinAnswer] = Field(default_factory=list)


class MobileChatMessage(BaseModel):
    id: UUID
    chat_session_id: UUID
    sender_type: str
    message_type: str
    ordinal: int
    body: str
    structured_payload: dict[str, Any] = Field(default_factory=dict)
    retrieval_filters: dict[str, Any] = Field(default_factory=dict)
    safety_labels: list[str] = Field(default_factory=list)
    created_at: datetime
    updated_at: datetime


class MobileChatMessageCreateRequest(BaseModel):
    body: str = Field(min_length=3, max_length=1600)
    filters: dict[str, Any] = Field(default_factory=dict)


class MobileChatExchangeResponse(BaseModel):
    user_message: MobileChatMessage
    assistant_message: MobileChatMessage
    answer: EvidenceAnswer
    retrieved: list[SearchResult]


class CounselorQueueCase(BaseModel):
    id: UUID
    case_key: str
    case_type: str
    severity: str
    status: str
    title: str
    summary: str | None = None
    privacy_override_active: bool
    opened_at: datetime
    student_name: str


class CounselorQueueSignal(BaseModel):
    id: UUID
    signal_type: str
    severity: str
    signal_status: str
    title: str
    signal_summary: str | None = None
    triggered_at: datetime
    student_name: str


class CounselorQueueHelpRequest(BaseModel):
    id: UUID
    category: str
    urgency: str
    status: str
    summary: str
    created_at: datetime
    student_name: str


class CounselorQueueResponse(BaseModel):
    open_cases: list[CounselorQueueCase] = Field(default_factory=list)
    unassigned_signals: list[CounselorQueueSignal] = Field(default_factory=list)
    open_help_requests: list[CounselorQueueHelpRequest] = Field(default_factory=list)


class CounselorDashboardMetricResponse(BaseModel):
    id: UUID
    metric_scope: str
    scope_key: str
    period_start: date
    period_end: date
    metrics: dict[str, Any] = Field(default_factory=dict)
    generation_version: str
    generated_at: datetime


class CounselorCaseNote(BaseModel):
    id: UUID
    note_type: str
    visibility_scope: str
    body: str
    created_at: datetime
    author_name: str | None = None


class CounselorCaseEvent(BaseModel):
    id: UUID
    event_type: str
    event_summary: str | None = None
    event_payload: dict[str, Any] = Field(default_factory=dict)
    occurred_at: datetime
    actor_name: str | None = None


class CounselorCaseAssignment(BaseModel):
    id: UUID
    assignment_role: str
    status: str
    assigned_at: datetime
    assigned_user_name: str


class CounselorCaseOverview(BaseModel):
    id: UUID
    case_key: str
    case_type: str
    severity: str
    status: str
    title: str
    summary: str | None = None
    privacy_override_active: bool
    override_reason: str | None = None
    opened_at: datetime
    closed_at: datetime | None = None
    student_name: str


class CounselorCaseDetailResponse(BaseModel):
    case: CounselorCaseOverview
    notes: list[CounselorCaseNote] = Field(default_factory=list)
    events: list[CounselorCaseEvent] = Field(default_factory=list)
    assignments: list[CounselorCaseAssignment] = Field(default_factory=list)


class CounselorCaseNoteCreateRequest(BaseModel):
    note_type: Literal["internal", "summary", "guardian_safe", "teacher_safe", "student_safe"] = "internal"
    visibility_scope: SummaryVisibilityScope = "safeguarding_only"
    body: str = Field(min_length=3, max_length=4000)


class GamePlayerBootstrapRequest(BaseModel):
    player_key: str = Field(min_length=24, max_length=200)
    display_name: str = Field(default="Adventurer", min_length=1, max_length=40)
    age_years: int = Field(default=10, ge=9, le=19)


class GameLocationProgress(BaseModel):
    location_id: str
    chapter: int = 1
    last_choice: str | None = None


class GameNpcState(BaseModel):
    npc_id: str
    friendship_level: int = 1
    current_mood: str = "curious"
    memories: list[str] = Field(default_factory=list)


class GamePlayerStateResponse(BaseModel):
    player_id: UUID
    display_name: str
    age_years: int
    xp: int
    coins: int
    stars: int
    current_day: int
    pet: str
    avatar: dict[str, Any] = Field(default_factory=dict)
    locations: list[GameLocationProgress] = Field(default_factory=list)
    npcs: list[GameNpcState] = Field(default_factory=list)


class GameProfileUpdateRequest(BaseModel):
    display_name: str | None = Field(default=None, min_length=1, max_length=40)
    pet: Literal["Fox", "Dragon", "Owl", "Panda"] | None = None
    avatar: dict[str, Any] | None = None


class GameSceneResponse(BaseModel):
    location_id: str
    chapter: int
    title: str
    body: str
    prompt: str
    npc_id: str
    evidence_count: int = 0


class GameChoiceRequest(BaseModel):
    location_id: str = Field(min_length=2, max_length=60)
    answer: str = Field(min_length=1, max_length=600)
    is_custom: bool = False
    expected_chapter: int = Field(ge=1)


class GameChoiceResponse(BaseModel):
    state: GamePlayerStateResponse
    message: str
    memory: str
    xp_earned: int
    coins_earned: int
    stars_earned: int


class GameCompanionRequest(BaseModel):
    message: str = Field(min_length=1, max_length=1200)


class GameCompanionResponse(BaseModel):
    answer: str
    emergency: bool = False
    evidence_sources: list[Citation] = Field(default_factory=list)
