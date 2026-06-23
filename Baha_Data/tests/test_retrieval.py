from uuid import uuid4

from baha_rag.retrieval.hybrid import HybridRetriever
from baha_rag.schemas import ChunkMetadata, Citation, SearchResult
from baha_rag.embeddings.indexer import IncrementalEmbeddingIndexer


def result(text: str, dense: float = 0.0, lexical: float = 0.0) -> SearchResult:
    return SearchResult(
        chunk_id=uuid4(),
        document_id=uuid4(),
        text=text,
        metadata=ChunkMetadata(source="who.int", organization="WHO"),
        citations=[],
        dense_score=dense,
        lexical_score=lexical,
    )


def test_rrf_sets_confidence_and_orders_results() -> None:
    retriever = HybridRetriever(repository=None, embeddings=None)  # type: ignore[arg-type]
    first = result("dense")
    second = result("lexical")
    fused = retriever._reciprocal_rank_fusion(dense=[first], lexical=[second])
    assert len(fused) == 2
    assert fused[0].confidence == 1.0
    assert all(item.confidence > 0 for item in fused)


def test_weighted_rerank_prioritizes_authoritative_relevant_result() -> None:
    retriever = HybridRetriever(repository=None, embeddings=None)  # type: ignore[arg-type]
    authoritative = SearchResult(
        chunk_id=uuid4(),
        document_id=uuid4(),
        text="Anxiety signs and support for adolescents.",
        metadata=ChunkMetadata(
            source="baha.example",
            organization="Bangalore Adolescent Health Academy",
            topic="anxiety",
            condition="anxiety",
        ),
        citations=[
            Citation(
                title="BAHA anxiety guide",
                organization="Bangalore Adolescent Health Academy",
                source="baha.example",
            )
        ],
        dense_score=0.8,
        lexical_score=2.0,
    )
    generic = SearchResult(
        chunk_id=uuid4(),
        document_id=uuid4(),
        text="General adolescent information.",
        metadata=ChunkMetadata(source="other.example", organization="Other"),
        citations=[],
        dense_score=0.8,
        lexical_score=0.1,
    )

    ranked = retriever._weighted_rerank(
        query="signs of anxiety",
        dense=[generic, authoritative],
        lexical=[authoritative],
        graph_context={"terms": ["anxiety", "symptom"]},
    )

    assert ranked[0].chunk_id == authoritative.chunk_id
    assert ranked[0].confidence > ranked[1].confidence


def test_final_results_keep_one_chunk_per_document() -> None:
    retriever = HybridRetriever(repository=None, embeddings=None)  # type: ignore[arg-type]
    document_id = uuid4()
    first = result("first", dense=0.9)
    second = result("second", dense=0.8)
    first.document_id = document_id
    second.document_id = document_id

    unique = retriever._unique_documents([first, second])

    assert unique == [first]


def test_embedding_fallback_is_traceable_metadata() -> None:
    indexer = object.__new__(IncrementalEmbeddingIndexer)
    fallback = indexer._fallback_resource_text(
        {
            "title": "Scanned school wellbeing guide",
            "organization": "NIMHANS",
            "topic": "stress",
            "source": "nimhans.ac.in",
            "url": "https://nimhans.ac.in/guide.pdf",
            "extracted_metadata": {},
        }
    )

    assert "Scanned school wellbeing guide" in fallback
    assert "NIMHANS" in fallback
    assert "https://nimhans.ac.in/guide.pdf" in fallback
