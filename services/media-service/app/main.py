# main.py

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.kafka.producer import stop_producer
from app.routers.upload import router as upload_router
from app.services.minio import ensure_bucket

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    await ensure_bucket()
    logger.info("MinIO bucket ready")
    yield
    await stop_producer()
    logger.info("Kafka producer stopped")


app = FastAPI(title="Media Service", version="0.1.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(upload_router)


@app.get("/health")
async def health():
    return {"status": "healthy"}