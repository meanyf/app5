# main.py

import asyncio
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.db.session import get_db
from app.kafka.consumer import consume_moderation_results
from app.routers.activities import router as activities_router

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # старт — запускаем консьюмер в фоне
    task = asyncio.create_task(consume_moderation_results())
    logger.info("Kafka consumer task started")
    yield
    # остановка — отменяем задачу
    task.cancel()
    try:
        await task
    except asyncio.CancelledError:
        logger.info("Kafka consumer task stopped")


app = FastAPI(
    title="Activity Service",
    version="0.1.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(activities_router)

settings = get_settings()


@app.get("/")
async def root():
    return {"message": "Activity Service работает! 🚀", "status": "ok"}


@app.get("/health")
async def health():
    return {"status": "healthy"}


@app.get("/health/db")
async def health_db(db: AsyncSession = Depends(get_db)):
    try:
        await db.execute(text("SELECT 1"))
        return {
            "status": "connected",
            "message": "Успешно подключено к PostgreSQL + PostGIS",
            "database": settings.ACTIVITY_DB_NAME,
        }
    except Exception as e:
        return {"status": "error", "message": str(e)}