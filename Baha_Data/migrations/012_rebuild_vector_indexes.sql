-- Rebuild IVFFlat indexes after the first full embedding population.
-- Creating these indexes against empty tables produces poor cluster centroids.

drop index if exists resource_embeddings_ivfflat_idx;
create index resource_embeddings_ivfflat_idx
  on resource_embeddings using ivfflat (embedding vector_cosine_ops)
  with (lists = 100);

drop index if exists condition_embeddings_ivfflat_idx;
create index condition_embeddings_ivfflat_idx
  on condition_embeddings using ivfflat (embedding vector_cosine_ops)
  with (lists = 10);

drop index if exists knowledge_embeddings_ivfflat_idx;
create index knowledge_embeddings_ivfflat_idx
  on knowledge_embeddings using ivfflat (embedding vector_cosine_ops)
  with (lists = 200);

analyze resource_embeddings;
analyze condition_embeddings;
analyze knowledge_embeddings;
