from __future__ import annotations

from collections import Counter
from pathlib import Path
from re import findall, sub
from typing import Any
from xml.etree import ElementTree
from zipfile import BadZipFile, ZipFile

from bs4 import BeautifulSoup
from pypdf import PdfReader

from baha_rag.acquisition.topics import TOPIC_ALIASES, classify_topic


CLINICAL_FIELDS = {
    "definition": ("definition", "defined", "refers to", "is a"),
    "symptoms": ("symptom", "sign", "warning sign"),
    "risk_factors": ("risk factor", "risk", "associated with"),
    "protective_factors": ("protective", "resilience", "supportive"),
    "parent_signs": ("parent", "caregiver", "home"),
    "teacher_signs": ("teacher", "school", "classroom"),
    "assessment_methods": ("assessment", "screening", "questionnaire"),
    "interventions": ("intervention", "support", "management", "prevention"),
    "parent_interventions": ("parent", "caregiver", "family"),
    "teacher_interventions": ("teacher", "classroom", "school"),
    "counselor_interventions": ("counselor", "counselling", "referral"),
    "classroom_support": ("classroom", "school support", "accommodation"),
    "family_support": ("family support", "caregiver", "home"),
    "escalation_indicators": ("escalation", "refer", "urgent"),
    "emergency_indicators": ("emergency", "suicide", "self-harm", "overdose"),
    "references": ("reference", "bibliography", "source"),
}

TAXONOMY_CONDITION_MAP = {
    "anxiety": "Anxiety",
    "depression": "Depression",
    "stress": "Stress",
    "burnout": "Burnout",
    "loneliness": "Loneliness",
    "grief": "Grief",
    "emotional regulation": "Emotional Regulation",
    "bullying": "Bullying",
    "cyberbullying": "Cyberbullying",
    "peer pressure": "Peer Pressure",
    "social isolation": "Social Isolation",
    "exam stress": "Exam Stress",
    "school refusal": "School Refusal",
    "school avoidance": "School Avoidance",
    "performance anxiety": "Performance Anxiety",
    "adhd": "ADHD",
    "autism": "Autism",
    "learning difficulties": "Learning Difficulties",
    "sleep": "Sleep Disorders",
    "gaming addiction": "Gaming Addiction",
    "internet addiction": "Internet Addiction",
    "physical activity": "Physical Inactivity",
    "self harm": "Self Harm",
    "suicide prevention": "Suicide Prevention",
    "substance abuse": "Substance Abuse",
    "anger": "Anger",
    "risk taking": "Risk Taking",
}

SKILL_TOPICS = (
    "communication skills",
    "decision making",
    "emotional intelligence",
    "problem solving",
    "resilience",
    "self awareness",
    "peer pressure",
    "risk taking",
    "performance anxiety",
    "digital wellness",
    "screen time",
    "bullying",
    "cyberbullying",
    "school refusal",
    "school avoidance",
)

SKILL_SUPPORT_FIELDS = {
    "protective_factors": (
        "protective",
        "resilience",
        "connectedness",
        "belonging",
        "supportive relationship",
        "coping skill",
    ),
    "interventions": (
        "intervention",
        "strategy",
        "practice",
        "activity",
        "lesson",
        "programme",
        "program",
        "implementation",
    ),
    "teacher_support": (
        "teacher",
        "educator",
        "classroom",
        "teaching practice",
    ),
    "parent_support": (
        "parent",
        "caregiver",
        "family",
        "at home",
    ),
    "school_support": (
        "whole school",
        "schoolwide",
        "school-wide",
        "district",
        "school policy",
        "student support team",
        "attendance team",
    ),
}


class KnowledgeExtractionService:
    def extract(self, storage_uri: str, metadata: dict[str, Any]) -> dict[str, Any]:
        text = self._clean_text(
            self._read_text(storage_uri, metadata.get("resource_type"))
        )
        title = metadata.get("title") or ""
        topic, subtopic = classify_topic(title)
        if not topic:
            topic, subtopic = classify_topic(text[:10000])
        keywords = self._keywords(text)
        clinical_profiles = self._clinical_profiles(title, text)
        condition = TAXONOMY_CONDITION_MAP.get(topic or "")
        skill_profile = self._skill_profile(title, text)
        return {
            "condition": condition,
            "topic": topic or metadata.get("topic"),
            "subtopic": subtopic or metadata.get("subtopic"),
            "audience": self._audience(
                title=title,
                text=text,
                configured=metadata.get("audience"),
            ),
            "summary": self._summary(text),
            "keywords": keywords,
            "entities": self._entities(text),
            "recommended_age_group": self._recommended_age_group(title, text),
            "skills": skill_profile["skills"],
            "protective_factors": skill_profile["protective_factors"],
            "interventions": skill_profile["interventions"],
            "teacher_support": skill_profile["teacher_support"],
            "parent_support": skill_profile["parent_support"],
            "school_support": skill_profile["school_support"],
            "clinical_profile": clinical_profiles.get(condition) if condition else None,
            "clinical_profiles": clinical_profiles,
            "text_word_count": len(text.split()),
        }

    def _clean_text(self, text: str) -> str:
        # PostgreSQL rejects NUL bytes; other ASCII controls are extraction noise.
        return sub(r"[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]", " ", text)

    def _read_text(self, storage_uri: str, resource_type: str | None) -> str:
        path = Path(storage_uri)
        if resource_type == "pdf" or path.suffix.lower() == ".pdf":
            try:
                reader = PdfReader(str(path))
                return "\n".join(page.extract_text() or "" for page in reader.pages[:50])
            except Exception:
                return ""
        if resource_type == "docx" or path.suffix.lower() == ".docx":
            return self._open_xml_text(path, ("word/document.xml",))
        if resource_type == "powerpoint" or path.suffix.lower() == ".pptx":
            return self._open_xml_text(path, ("ppt/slides/slide",))
        if resource_type == "video_transcript" or path.suffix.lower() in {
            ".txt", ".md", ".vtt", ".srt"
        }:
            return self._transcript_text(path)
        html = path.read_text(errors="ignore")
        return BeautifulSoup(html, "html.parser").get_text(" ", strip=True)

    def _open_xml_text(self, path: Path, member_prefixes: tuple[str, ...]) -> str:
        try:
            with ZipFile(path) as package:
                members = sorted(
                    name
                    for name in package.namelist()
                    if any(
                        name == prefix or name.startswith(prefix)
                        for prefix in member_prefixes
                    )
                    and name.endswith(".xml")
                )
                fragments: list[str] = []
                for member in members:
                    root = ElementTree.fromstring(package.read(member))
                    fragments.extend(node.text or "" for node in root.iter() if node.text)
                return " ".join(fragments)
        except (BadZipFile, ElementTree.ParseError, OSError):
            return ""

    def _transcript_text(self, path: Path) -> str:
        text = path.read_text(errors="ignore")
        lines = []
        for line in text.splitlines():
            clean = line.strip()
            if not clean or clean == "WEBVTT":
                continue
            if "-->" in clean or clean.isdigit():
                continue
            lines.append(clean)
        return " ".join(lines)

    def _summary(self, text: str) -> str:
        clean = " ".join(text.split())
        return clean[:1200]

    def _keywords(self, text: str) -> list[str]:
        words = [
            word.lower()
            for word in findall(r"[A-Za-z][A-Za-z-]{3,}", text)
            if word.lower() not in {"with", "that", "this", "from", "have", "will", "your", "more"}
        ]
        return [word for word, _ in Counter(words).most_common(20)]

    def _entities(self, text: str) -> list[str]:
        candidates = findall(r"\b[A-Z][A-Za-z]+(?:\s+[A-Z][A-Za-z]+){0,3}\b", text)
        return [entity for entity, _ in Counter(candidates).most_common(20)]

    def _recommended_age_group(self, title: str, text: str) -> str:
        searchable = f"{title} {text[:20000]}".lower()
        age_terms = (
            ("ages 16-18", ("ages 16", "ages 17", "ages 18", "upper secondary", "high school")),
            ("ages 13-15", ("ages 13", "ages 14", "ages 15", "middle school", "secondary school")),
            ("ages 10-12", ("ages 10", "ages 11", "ages 12", "upper primary")),
            ("adolescent", ("adolescent", "teenager", "teen", "young people", "youth")),
            ("school age", ("student", "school-age", "school aged", "classroom")),
        )
        for age_group, terms in age_terms:
            if any(term in searchable for term in terms):
                return age_group
        return "all ages"

    def _skill_profile(self, title: str, text: str) -> dict[str, list[str]]:
        searchable = f"{title} {text}".lower()
        skills = [
            topic
            for topic in SKILL_TOPICS
            if any(alias in searchable for alias in TOPIC_ALIASES.get(topic, (topic,)))
        ]
        sentences = [
            sentence.strip() + "."
            for sentence in text.replace("\n", " ").split(".")
            if 6 <= len(sentence.strip().split()) <= 80
        ]
        profile: dict[str, list[str]] = {"skills": skills}
        for field, terms in SKILL_SUPPORT_FIELDS.items():
            profile[field] = [
                sentence
                for sentence in sentences
                if any(term in sentence.lower() for term in terms)
            ][:12]
        return profile

    def _audience(self, *, title: str, text: str, configured: str | None) -> str:
        title_lower = title.lower()
        text_lower = text.lower()
        audience_terms = {
            "parent": ("parent", "caregiver", "family"),
            "teacher": ("teacher", "classroom", "school staff", "educator"),
            "counselor": ("counselor", "counsellor", "school psychologist"),
            "adolescent": ("adolescent", "teen", "young person", "youth"),
        }
        scores = {
            audience: sum(title_lower.count(term) * 8 + text_lower.count(term) for term in terms)
            for audience, terms in audience_terms.items()
        }
        best = max(scores, key=scores.get)
        if scores[best]:
            return best
        return configured or "general"

    def _clinical_profiles(self, title: str, text: str) -> dict[str, dict[str, Any]]:
        searchable = f"{title} {text}".lower()
        profiles: dict[str, dict[str, Any]] = {}
        for topic, condition in TAXONOMY_CONDITION_MAP.items():
            aliases = (topic,)
            if topic == "suicide prevention":
                aliases = ("suicide prevention", "suicidal ideation", "suicide risk")
            if any(alias in searchable for alias in aliases):
                profile = self._clinical_profile(topic, text)
                if profile:
                    profiles[condition] = profile
        return profiles

    def _clinical_profile(self, topic: str | None, text: str) -> dict[str, Any] | None:
        condition = TAXONOMY_CONDITION_MAP.get(topic or "")
        if not condition:
            return None
        sentences = [sentence.strip() for sentence in text.replace("\n", " ").split(".") if sentence.strip()]
        profile: dict[str, Any] = {"condition": condition}
        for field, terms in CLINICAL_FIELDS.items():
            matches = [
                sentence + "."
                for sentence in sentences
                if any(term in sentence.lower() for term in terms)
            ][:10]
            profile[field] = matches[0] if field == "definition" and matches else matches
        return profile
