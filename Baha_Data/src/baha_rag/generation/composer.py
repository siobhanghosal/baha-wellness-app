from __future__ import annotations

from baha_rag.safety import SAFETY_NOTE, assess_safety, safe_join_evidence
from baha_rag.schemas import Citation, EvidenceAnswer, Perspective, SearchResult


class EvidenceComposer:
    """Composes bounded answers from retrieved evidence chunks.

    A production deployment can swap this for an LLM provider, but the same
    contract should remain: evidence in, cited structured answer out.
    """

    def compose(
        self,
        *,
        condition: str,
        perspective: Perspective,
        query: str,
        evidence: list[SearchResult],
    ) -> EvidenceAnswer:
        safety = assess_safety(query)
        if not evidence:
            return EvidenceAnswer(
                perspective=perspective,
                condition=condition,
                what_it_is=(
                    "No approved evidence was retrieved for this question, so the system cannot provide "
                    "an evidence-based explanation."
                ),
                how_to_identify_it=(
                    "No approved retrieved source is available for identification guidance in this response."
                ),
                what_to_do=(
                    "Consult a qualified professional, school counselor, or trusted adult for situation-specific support."
                ),
                when_to_seek_help=(
                    "Seek urgent help immediately if there is self-harm, suicidal thoughts, overdose, abuse, "
                    "or danger to anyone."
                ),
                safety_note=SAFETY_NOTE,
                evidence_sources=[],
                confidence=0.0,
            )
        citations = self._dedupe_citations(evidence)
        confidence = round(sum(item.confidence for item in evidence[:5]) / max(len(evidence[:5]), 1), 4)
        snippets = [item.text for item in evidence[:5]]

        what_it_is = safe_join_evidence(
            [self._sentence_with_terms(snippet, ("definition", "refers to", "is a")) for snippet in snippets],
            f"{condition} is described in the retrieved sources as an adolescent wellbeing topic requiring supportive, non-judgmental attention.",
        )
        identify_terms = ("sign", "symptom", "identify", "notice", "warning")
        how_to_identify = safe_join_evidence(
            [self._sentence_with_terms(snippet, identify_terms) for snippet in snippets],
            "Look for persistent changes in mood, behavior, sleep, school participation, peer relationships, or daily functioning.",
        )
        support_terms = ("support", "intervention", "help", "strategy", "recommend")
        what_to_do = safe_join_evidence(
            [self._sentence_with_terms(snippet, support_terms) for snippet in snippets],
            self._default_action(perspective),
        )
        seek_help = (
            "Seek professional help when concerns persist, worsen, impair daily life, involve substance use, "
            "or include self-harm, suicidal thoughts, abuse, overdose, or danger to anyone."
        )
        if safety.emergency_indicators:
            seek_help = (
                "Emergency indicators are present. Contact local emergency services or an appropriate crisis "
                "service immediately, stay with the young person when safe to do so, and involve a trusted adult."
            )

        return EvidenceAnswer(
            perspective=perspective,
            condition=condition,
            what_it_is=what_it_is,
            how_to_identify_it=how_to_identify,
            what_to_do=what_to_do,
            when_to_seek_help=seek_help,
            safety_note=SAFETY_NOTE,
            evidence_sources=citations,
            confidence=confidence,
        )

    def _sentence_with_terms(self, text: str, terms: tuple[str, ...]) -> str:
        sentences = [part.strip() for part in text.replace("\n", " ").split(".") if part.strip()]
        for sentence in sentences:
            lowered = sentence.lower()
            if any(term in lowered for term in terms):
                return sentence + "."
        return ""

    def _default_action(self, perspective: Perspective) -> str:
        actions = {
            "parent": "Offer calm support, listen without blame, maintain routines, and consult a qualified professional when concerns persist or escalate.",
            "teacher": "Document observable concerns, use supportive classroom adjustments, follow school safeguarding procedures, and involve counselors or guardians according to policy.",
            "counselor": "Use approved assessment and referral pathways, document risk indicators, coordinate with caregivers and school teams, and escalate emergencies immediately.",
            "adolescent": "Talk to a trusted adult, use healthy coping supports, avoid handling serious concerns alone, and seek professional help when safety or daily life is affected.",
        }
        return actions[perspective]

    def _dedupe_citations(self, evidence: list[SearchResult]) -> list[Citation]:
        seen = set()
        citations: list[Citation] = []
        for result in evidence:
            for citation in result.citations:
                key = (citation.title, citation.organization, citation.url)
                if key in seen:
                    continue
                seen.add(key)
                citations.append(citation)
        return citations
