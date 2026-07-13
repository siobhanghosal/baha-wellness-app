from fastapi import APIRouter

from baha_companion.authentication.router import router as authentication_router
from baha_companion.chat.router import router as chat_router
from baha_companion.chat.streaming import router as chat_streaming_router
from baha_companion.embeddings.router import router as embeddings_router
from baha_companion.health.router import router as health_router
from baha_companion.knowledge.router import router as knowledge_router
from baha_companion.llm.router import router as llm_router
from baha_companion.retrieval.router import router as retrieval_router
from baha_companion.users.router import router as users_router

api_router = APIRouter()
api_router.include_router(authentication_router)
api_router.include_router(users_router)
api_router.include_router(chat_router)
api_router.include_router(chat_streaming_router)
api_router.include_router(llm_router)
api_router.include_router(knowledge_router)
api_router.include_router(embeddings_router)
api_router.include_router(retrieval_router)

root_router = APIRouter()
root_router.include_router(health_router)
