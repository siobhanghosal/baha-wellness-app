#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DUMP_URL="${BAHA_SOLOMON_DUMP_URL:-https://media.githubusercontent.com/media/siobhanghosal/baha-wellness-app/Solomon_RAG_Vector_DB/backups/baha_rag_20260714-183725.dump}"
DUMP_PATH="${BAHA_SOLOMON_DUMP_PATH:-/private/tmp/baha_rag_20260714-183725.dump}"
BACKUP_PATH="${BAHA_CURRENT_RETRIEVAL_BACKUP_PATH:-/private/tmp/baha_current_retrieval_backup_$(date +%Y%m%d-%H%M%S).dump}"
POSTGRES_HOST="${BAHA_POSTGRES_HOST:-host.docker.internal}"
POSTGRES_PORT="${BAHA_POSTGRES_PORT:-5433}"
POSTGRES_DB="${BAHA_POSTGRES_DB:-baha_rag}"
POSTGRES_USER="${BAHA_POSTGRES_USER:-baha}"
POSTGRES_PASSWORD="${BAHA_POSTGRES_PASSWORD:-baha}"

echo "Downloading Solomon RAG dump to ${DUMP_PATH} ..."
curl -L "${DUMP_URL}" -o "${DUMP_PATH}"

echo "Backing up current retrieval tables to ${BACKUP_PATH} ..."
docker run --rm \
  -e PGPASSWORD="${POSTGRES_PASSWORD}" \
  -v /private/tmp:/backups \
  postgres:16 \
  pg_dump \
  -h "${POSTGRES_HOST}" \
  -p "${POSTGRES_PORT}" \
  -U "${POSTGRES_USER}" \
  -d "${POSTGRES_DB}" \
  -Fc \
  -f "/backups/$(basename "${BACKUP_PATH}")" \
  -t acquired_resources \
  -t condition_profiles \
  -t condition_embeddings \
  -t knowledge_graph_nodes \
  -t knowledge_graph_edges \
  -t knowledge_embeddings \
  -t resource_chunks \
  -t resource_embeddings \
  -t chat_answer_citations

echo "Clearing current retrieval tables ..."
docker exec baha_data-postgres-1 psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -v ON_ERROR_STOP=1 -c \
  "truncate table chat_answer_citations, resource_embeddings, resource_chunks, knowledge_embeddings, knowledge_graph_edges, knowledge_graph_nodes, condition_embeddings, condition_profiles, acquired_resources restart identity cascade;"

echo "Restoring Solomon retrieval corpus ..."
docker run --rm \
  -e PGPASSWORD="${POSTGRES_PASSWORD}" \
  -v /private/tmp:/backups \
  postgres:16 \
  pg_restore \
  -h "${POSTGRES_HOST}" \
  -p "${POSTGRES_PORT}" \
  -U "${POSTGRES_USER}" \
  -d "${POSTGRES_DB}" \
  --data-only \
  --disable-triggers \
  --no-owner \
  --no-privileges \
  -t acquired_resources \
  -t condition_profiles \
  -t condition_embeddings \
  -t knowledge_graph_nodes \
  -t knowledge_graph_edges \
  -t knowledge_embeddings \
  -t resource_chunks \
  -t resource_embeddings \
  "/backups/$(basename "${DUMP_PATH}")"

echo "Import complete. Current retrieval table counts:"
docker exec baha_data-postgres-1 psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -P pager=off -c \
  "select 'acquired_resources' as table_name, count(*) from acquired_resources
   union all select 'resource_chunks', count(*) from resource_chunks
   union all select 'resource_embeddings', count(*) from resource_embeddings
   union all select 'knowledge_graph_nodes', count(*) from knowledge_graph_nodes
   union all select 'knowledge_graph_edges', count(*) from knowledge_graph_edges
   union all select 'knowledge_embeddings', count(*) from knowledge_embeddings
   union all select 'condition_profiles', count(*) from condition_profiles
   union all select 'condition_embeddings', count(*) from condition_embeddings
   union all select 'chat_answer_citations', count(*) from chat_answer_citations;"
