from __future__ import annotations

import re
from collections import defaultdict

from baha_companion.knowledge.types import BlockKind, ParsedBlock, ParsedDocument, SegmentedSection


SECTION_ALIASES = {
    "definition": {"definition", "overview", "what is", "introduction"},
    "symptoms": {"symptoms", "signs", "warning signs"},
    "causes": {"causes", "why it happens"},
    "risk_factors": {"risk factors", "risks"},
    "protective_factors": {"protective factors"},
    "parent_guidance": {"for parents", "parent guidance", "parent tips", "caregivers"},
    "teacher_guidance": {"for teachers", "teacher guidance", "teacher tips", "educators"},
    "student_guidance": {"for students", "student guidance", "student tips", "young people"},
    "activities": {"activities", "exercise", "exercises", "practice", "toolkit"},
    "faqs": {"faq", "faqs", "frequently asked questions", "questions"},
    "references": {"references", "citations", "sources", "bibliography"},
    "treatment": {"treatment", "support", "management", "intervention"},
}


class DocumentSegmentationService:
    def segment(self, document: ParsedDocument) -> list[SegmentedSection]:
        sections: list[SegmentedSection] = []
        current_title = document.title or document.source_path.stem
        current_type = self._canonical_section_type(current_title)
        current_blocks: list[ParsedBlock] = []

        for block in document.blocks:
            if block.kind == BlockKind.HEADING:
                if current_blocks:
                    sections.append(self._build_section(current_title, current_type, current_blocks, len(sections)))
                current_title = block.text
                current_type = self._canonical_section_type(block.text)
                current_blocks = []
                continue
            current_blocks.append(block)

        if current_blocks:
            sections.append(self._build_section(current_title, current_type, current_blocks, len(sections)))

        if not sections and document.blocks:
            sections.append(
                self._build_section(
                    document.title or document.source_path.stem,
                    self._canonical_section_type(document.title or "overview"),
                    document.blocks,
                    0,
                )
            )
        return sections

    def extract_faqs(self, section: SegmentedSection) -> list[dict[str, str]]:
        if section.section_type != "faqs":
            return []
        question_pattern = re.compile(r"(?P<question>[^?]+\?)\s*(?P<answer>.+)")
        faqs: list[dict[str, str]] = []
        for line in section.body.split(" - "):
            match = question_pattern.match(line.strip())
            if match:
                faqs.append(
                    {
                        "question": match.group("question").strip(),
                        "answer": match.group("answer").strip(),
                    }
                )
        return faqs

    def extract_activities(self, section: SegmentedSection) -> list[dict[str, str]]:
        if section.section_type != "activities":
            return []
        activities: list[dict[str, str]] = []
        for index, sentence in enumerate([item.strip() for item in section.body.split(" - ") if item.strip()], start=1):
            activities.append({"title": f"Activity {index}", "body": sentence, "activity_type": "exercise"})
        return activities

    def extract_citations(self, sections: list[SegmentedSection]) -> list[dict[str, str]]:
        citations: list[dict[str, str]] = []
        for section in sections:
            if section.section_type != "references":
                continue
            for line in [item.strip() for item in section.body.split(" - ") if item.strip()]:
                citations.append({"text": line, "url": ""})
        return citations

    def _build_section(
        self,
        title: str,
        section_type: str,
        blocks: list[ParsedBlock],
        order: int,
    ) -> SegmentedSection:
        body_lines = [block.text for block in blocks]
        list_counts = defaultdict(int)
        for block in blocks:
            list_counts[block.kind] += 1
        return SegmentedSection(
            title=title[:255],
            body=" ".join(body_lines).strip(),
            section_type=section_type,
            order=order,
            metadata={"list_item_count": list_counts[BlockKind.LIST_ITEM]},
        )

    def _canonical_section_type(self, heading: str) -> str:
        lowered = heading.lower().strip()
        for canonical, aliases in SECTION_ALIASES.items():
            if any(alias in lowered for alias in aliases):
                return canonical
        return "overview"

