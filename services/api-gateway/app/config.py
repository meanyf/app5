# config.py

from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_ignore_empty=True,
        extra="ignore",
    )

    # JWT (тот же секрет что и в auth-service)
    JWT_SECRET: str
    JWT_ALGORITHM: str = "HS256"

    # Внутренние адреса сервисов
    ACTIVITY_SERVICE_URL: str = "http://activity-service:8000"
    AUTH_SERVICE_URL: str = "http://auth-service:8000"
    CHAT_SERVICE_URL: str = "http://chat-service:8000"
    MEDIA_SERVICE_URL: str = "http://media-service:8000"
    USER_SERVICE_URL: str = "http://user-service:8000"


@lru_cache()
def get_settings() -> Settings:
    return Settings()