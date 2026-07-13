from __future__ import annotations

import re
from dataclasses import dataclass, field
from typing import Any

from baha_companion.llm.context_composer import ContextPackage


UNSAFE_PATTERNS = (
    r"\bignore your doctor\b",
    r"\bstop taking\b",
    r"\byou (definitely|certainly) have\b",
    r"\bself-medicate\b",
    r"\bguaranteed cure\b",
)
HALLUCINATION_PATTERNS = (
    r"\baccording to studies\b",
    r"\bresearch proves\b",
    r"\bexperts agree\b",
)


@dataclass(slots=True)
class ValidationIssue:
    code: str
    detail: str


@dataclass(slots=True)
class ValidatedResponse:
    content: str
    citations: list[dict[str, Any]]
    markdown: bool
    issues: list[ValidationIssue] = field(default_factory=list)
    sufficient_evidence: bool = True


class ResponseValidator:
    def validate(self, *, content: str, context_package: ContextPackage, require_citations: bool) -> ValidatedResponse:
        issues: list[ValidationIssue] = []
        cleaned = content.strip()
        if not cleaned:
            issues.append(ValidationIssue(code="empty_response", detail="The model returned an empty response."))
            cleaned = self._insufficient_evidence_message(context_package)

        if any(re.search(pattern, cleaned, flags=re.IGNORECASE) for pattern in UNSAFE_PATTERNS):
            issues.append(ValidationIssue(code="unsafe_advice", detail="Unsafe advice detected in model output."))
            cleaned = self._insufficient_evidence_message(context_package)

        if any(re.search(pattern, cleaned, flags=re.IGNORECASE) for pattern in HALLUCINATION_PATTERNS) and not re.search(
            r"\[S\d+\]",
            cleaned,
        ):
            issues.append(
                ValidationIssue(
                    code="hallucination_indicator",
                    detail="Evidence-like claims were present without source markers.",
                )
            )

        if require_citations and context_package.entries and not re.search(r"\[S\d+\]", cleaned):
            issues.append(ValidationIssue(code="missing_citations", detail="Response did not include source markers."))
            citation_suffix = " ".join(f"[{entry.source_id}]" for entry in context_package.entries[:2])
            cleaned = f"{cleaned}\n\nSources: {citation_suffix}".strip()

        if not context_package.entries or not context_package.has_sufficient_evidence:
            issues.append(
                ValidationIssue(
                    code="insufficient_evidence",
                    detail="Retrieved evidence was absent or too weak for a confident factual answer.",
                )
            )
            if "don't have enough evidence" not in cleaned.lower():
                cleaned = self._insufficient_evidence_message(context_package)

        cited_ids = set(re.findall(r"\[(S\d+)\]", cleaned))
        citations = [
            citation
            for entry in context_package.entries
            for citation in entry.citations
            if citation["source_id"] in cited_ids
        ]
        return ValidatedResponse(
            content=cleaned,
            citations=citations,
            markdown=True,
            issues=issues,
            sufficient_evidence=context_package.has_sufficient_evidence,
        )

    def _insufficient_evidence_message(self, context_package: ContextPackage) -> str:
        citation_suffix = " ".join(f"[{entry.source_id}]" for entry in context_package.entries[:2])
        if citation_suffix:
            citation_suffix = f" {citation_suffix}"
        return (
            "I don't have enough strong evidence in the retrieved sources to answer that confidently. "
            "I can share cautious, general support ideas and recommend checking with a trusted adult, "
            "teacher, counsellor, or healthcare professional for personalized guidance."
            f"{citation_suffix}"
        )
