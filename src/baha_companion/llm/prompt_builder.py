from __future__ import annotations

from dataclasses import dataclass
from enum import StrEnum

from baha_companion.chat.models import Message
from baha_companion.llm.context_composer import ContextPackage


class PromptProfile(StrEnum):
    STUDENT = "student"
    AGE_9_12_MALE = "9_12_male"
    AGE_9_12_FEMALE = "9_12_female"
    AGE_13_16_MALE = "13_16_male"
    AGE_13_16_FEMALE = "13_16_female"
    AGE_17_19_MALE = "17_19_male"
    AGE_17_19_FEMALE = "17_19_female"
    PARENT = "parent"
    TEACHER = "teacher"
    COUNSELLOR = "counsellor"
    ADMINISTRATOR = "administrator"


@dataclass(frozen=True, slots=True)
class PromptTemplate:
    audience: str
    reading_level: str
    tone: str
    examples: str
    activities: str
    preferred_length: str


PROMPT_TEMPLATES = {
    PromptProfile.STUDENT: PromptTemplate(
        audience="students",
        reading_level="plain, middle-school friendly language",
        tone="warm, encouraging, direct, and calm",
        examples="use relatable school, friendship, routine, and exam-pressure examples",
        activities="offer 1-3 simple activities when helpful",
        preferred_length="keep the answer concise unless the user asks for more detail",
    ),
    PromptProfile.AGE_9_12_MALE: PromptTemplate(
        audience="boys ages 9-12",
        reading_level="short sentences and very simple vocabulary",
        tone="friendly, reassuring, and concrete",
        examples="use child-friendly examples from school, games, siblings, and bedtime routines",
        activities="suggest quick grounding or journaling activities that can be done with adult support",
        preferred_length="keep responses brief and easy to follow",
    ),
    PromptProfile.AGE_9_12_FEMALE: PromptTemplate(
        audience="girls ages 9-12",
        reading_level="short sentences and very simple vocabulary",
        tone="gentle, reassuring, and practical",
        examples="use child-friendly examples from school, friends, hobbies, and bedtime routines",
        activities="suggest quick breathing, drawing, or journaling activities with adult support",
        preferred_length="keep responses brief and easy to follow",
    ),
    PromptProfile.AGE_13_16_MALE: PromptTemplate(
        audience="boys ages 13-16",
        reading_level="clear teen-friendly language",
        tone="respectful, supportive, and non-preachy",
        examples="use examples about exams, sports, friendships, online life, and routines",
        activities="offer practical step-by-step coping activities",
        preferred_length="give a focused answer with concrete steps",
    ),
    PromptProfile.AGE_13_16_FEMALE: PromptTemplate(
        audience="girls ages 13-16",
        reading_level="clear teen-friendly language",
        tone="supportive, respectful, and calm",
        examples="use examples about exams, friendships, online pressure, and routines",
        activities="offer practical step-by-step coping activities",
        preferred_length="give a focused answer with concrete steps",
    ),
    PromptProfile.AGE_17_19_MALE: PromptTemplate(
        audience="young men ages 17-19",
        reading_level="clear secondary-school or early college level language",
        tone="collaborative, respectful, and practical",
        examples="use examples about college preparation, identity, independence, and stress",
        activities="suggest evidence-aligned routines and reflection prompts",
        preferred_length="be concise but mature in tone",
    ),
    PromptProfile.AGE_17_19_FEMALE: PromptTemplate(
        audience="young women ages 17-19",
        reading_level="clear secondary-school or early college level language",
        tone="collaborative, respectful, and practical",
        examples="use examples about college preparation, identity, independence, and stress",
        activities="suggest evidence-aligned routines and reflection prompts",
        preferred_length="be concise but mature in tone",
    ),
    PromptProfile.PARENT: PromptTemplate(
        audience="parents and caregivers",
        reading_level="plain language with practical family guidance",
        tone="supportive, trustworthy, and actionable",
        examples="use home, school, routine, and communication examples",
        activities="suggest co-regulation, listening, and support strategies",
        preferred_length="give structured guidance with a few clear steps",
    ),
    PromptProfile.TEACHER: PromptTemplate(
        audience="teachers",
        reading_level="professional but accessible language",
        tone="respectful, classroom-aware, and practical",
        examples="use classroom management, student support, and referral pathway examples",
        activities="include strategies that fit school settings",
        preferred_length="use compact, structured guidance",
    ),
    PromptProfile.COUNSELLOR: PromptTemplate(
        audience="school counsellors",
        reading_level="professional, evidence-aware language",
        tone="professional, calm, and boundaried",
        examples="use brief examples tied to psychoeducation and support planning",
        activities="include coping skills, psychoeducation, and escalation signals",
        preferred_length="provide structured, professional guidance",
    ),
    PromptProfile.ADMINISTRATOR: PromptTemplate(
        audience="school administrators",
        reading_level="clear administrative language",
        tone="professional, concise, and policy-aware",
        examples="use school systems, referral workflows, and wellbeing program examples",
        activities="focus on policy-safe actions and operational next steps",
        preferred_length="keep it concise and implementation-oriented",
    ),
}


class PromptBuilder:
    def build(
        self,
        *,
        profile: PromptProfile,
        question: str,
        conversation_summary: str | None,
        recent_messages: list[Message],
        context_package: ContextPackage,
    ) -> list[dict[str, str]]:
        template = PROMPT_TEMPLATES[profile]
        system_message = self._system_prompt(template)
        history_messages = [
            {"role": message.role.value, "content": message.content}
            for message in recent_messages
        ]
        final_user_message = self._final_user_prompt(
            question=question,
            conversation_summary=conversation_summary,
            context_package=context_package,
        )
        return [
            {"role": "system", "content": system_message},
            *history_messages,
            {"role": "user", "content": final_user_message},
        ]

    def infer_profile(
        self,
        *,
        explicit_profile: PromptProfile | None,
        audience: str | None,
        age_group: str | None,
        gender: str | None,
    ) -> PromptProfile:
        if explicit_profile is not None:
            return explicit_profile
        normalized_audience = (audience or "").strip().lower()
        normalized_age = (age_group or "").strip().lower()
        normalized_gender = (gender or "").strip().lower()
        if normalized_audience in {
            PromptProfile.PARENT.value,
            PromptProfile.TEACHER.value,
            PromptProfile.COUNSELLOR.value,
            PromptProfile.ADMINISTRATOR.value,
        }:
            return PromptProfile(normalized_audience)
        if normalized_age in {"9-12", "9_12", "9 to 12"}:
            return (
                PromptProfile.AGE_9_12_FEMALE
                if normalized_gender == "female"
                else PromptProfile.AGE_9_12_MALE
            )
        if normalized_age in {"13-16", "13_16", "13 to 16"}:
            return (
                PromptProfile.AGE_13_16_FEMALE
                if normalized_gender == "female"
                else PromptProfile.AGE_13_16_MALE
            )
        if normalized_age in {"17-19", "17_19", "17 to 19"}:
            return (
                PromptProfile.AGE_17_19_FEMALE
                if normalized_gender == "female"
                else PromptProfile.AGE_17_19_MALE
            )
        return PromptProfile.STUDENT

    def _system_prompt(self, template: PromptTemplate) -> str:
        return (
            "You are the BAHA Wellness Companion, an evidence-bound wellbeing assistant.\n"
            f"Audience: {template.audience}.\n"
            f"Reading level: {template.reading_level}.\n"
            f"Tone: {template.tone}.\n"
            f"Examples: {template.examples}.\n"
            f"Activities: {template.activities}.\n"
            f"Length: {template.preferred_length}.\n"
            "Use only the provided evidence when making factual claims.\n"
            "Cite evidence inline using source markers like [S1] or [S2].\n"
            "If the evidence is weak or incomplete, say that clearly.\n"
            "Never diagnose, never replace licensed professionals, never prescribe medications, "
            "and never advise someone to ignore urgent or professional help.\n"
            "If there is immediate safety risk, recommend reaching a trusted adult or local emergency support."
        )

    def _final_user_prompt(
        self,
        *,
        question: str,
        conversation_summary: str | None,
        context_package: ContextPackage,
    ) -> str:
        evidence_block = "\n\n".join(
            (
                f"[{entry.source_id}] Title: {entry.title}\n"
                f"Organisation: {entry.organisation or 'Unknown'}\n"
                f"Priority: {entry.priority or 'unknown'} | Evidence: {entry.evidence_level or 'unknown'}\n"
                f"Summary: {entry.summary or 'No summary provided.'}\n"
                f"Excerpt: {entry.excerpt}"
            )
            for entry in context_package.entries
        ) or "No supporting evidence was retrieved."
        return (
            "<conversation_summary>\n"
            f"{conversation_summary or 'No prior summary available.'}\n"
            "</conversation_summary>\n\n"
            "<retrieved_evidence>\n"
            f"{evidence_block}\n"
            "</retrieved_evidence>\n\n"
            "<response_requirements>\n"
            "- Answer the user directly and safely.\n"
            "- Use citations for factual claims.\n"
            "- Prefer the strongest evidence first.\n"
            "- If evidence is insufficient, say so explicitly.\n"
            "</response_requirements>\n\n"
            "<current_user_question>\n"
            f"{question}\n"
            "</current_user_question>"
        )
