from __future__ import annotations

import re

from baha_companion.knowledge.types import KnowledgeObjectDraft


class QualityService:
    def score(self, draft: KnowledgeObjectDraft) -> dict[str, float | list[str]]:
        warnings: list[str] = []
        completeness = self._completeness_score(draft)
        readability = self._readability_score(draft.body)
        metadata_completeness = self._metadata_score(draft)
        duplicate_likelihood = max(0.0, 1 - draft.duplicate_likelihood)
        extraction_confidence = draft.extraction_confidence
        reference_quality = min(1.0, 0.4 + (0.15 * len(draft.citations)))
        language_quality = self._language_quality(draft.body)

        if completeness < 0.6:
            warnings.append("incomplete_content")
        if readability < 0.45:
            warnings.append("difficult_to_read")
        if language_quality < 0.55:
            warnings.append("language_noise_detected")

        quality_score = round(
            (
                completeness
                + readability
                + metadata_completeness
                + duplicate_likelihood
                + extraction_confidence
                + reference_quality
                + language_quality
            )
            / 7
            * 100,
            2,
        )
        return {
            "quality_score": quality_score,
            "completeness_score": round(completeness, 2),
            "readability_score": round(readability, 2),
            "metadata_completeness_score": round(metadata_completeness, 2),
            "duplicate_likelihood_score": round(duplicate_likelihood, 2),
            "extraction_confidence_score": round(extraction_confidence, 2),
            "reference_quality_score": round(reference_quality, 2),
            "language_quality_score": round(language_quality, 2),
            "warnings": warnings,
        }

    def _completeness_score(self, draft: KnowledgeObjectDraft) -> float:
        score = 0.0
        if len(draft.body) >= 120:
            score += 0.35
        if draft.summary:
            score += 0.2
        if draft.topic:
            score += 0.15
        if draft.audience:
            score += 0.1
        if draft.age_group:
            score += 0.1
        if draft.organization:
            score += 0.1
        return min(1.0, score)

    def _readability_score(self, body: str) -> float:
        words = re.findall(r"\w+", body)
        sentences = max(1, len(re.findall(r"[.!?]", body)))
        average = len(words) / sentences
        if average <= 14:
            return 0.92
        if average <= 22:
            return 0.75
        if average <= 30:
            return 0.58
        return 0.38

    def _metadata_score(self, draft: KnowledgeObjectDraft) -> float:
        populated = sum(
            bool(value)
            for value in (
                draft.organization,
                draft.document_url,
                draft.publication_date,
                draft.country,
                draft.language,
                draft.keywords,
                draft.tags,
            )
        )
        return min(1.0, 0.3 + (populated * 0.1))

    def _language_quality(self, body: str) -> float:
        weird_sequences = len(re.findall(r"[^\w\s.,;:!?()'\"]{2,}", body))
        repeated_words = len(re.findall(r"\b(\w+)\s+\1\b", body.lower()))
        penalty = min(0.7, (weird_sequences * 0.08) + (repeated_words * 0.05))
        return max(0.25, 1 - penalty)

