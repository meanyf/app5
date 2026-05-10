# main.py

from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from .config import get_settings
from .db.session import get_db

app = FastAPI(
    title="Chat Service",
    description="Минимальный рабочий сервис",
    version="0.1.0"
)
from app.routers.chat import router as chat_router

app.include_router(chat_router)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

settings = get_settings()


@app.get("/")
async def root():
    return {
        "message": "chat Service работает! 🚀",
        "status": "ok",
    }


@app.get("/health")
async def health():
    return {"status": "healthy"}


# ← НОВАЯ ПРОВЕРКА ПОДКЛЮЧЕНИЯ К БД
@app.get("/health/db")
async def health_db(db: AsyncSession = Depends(get_db)):
    try:
        # Простой запрос к базе
        result = await db.execute(text("SELECT 1 as status"))
        
        return {
            "status": "connected",
            "message": "Успешно подключено к PostgreSQL + PostGIS",
            "database": settings.CHAT_DB_NAME
        }
    except Exception as e:
        return {
            "status": "error",
            "message": f"Ошибка подключения к базе: {str(e)}"
        }