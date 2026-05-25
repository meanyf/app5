# config.py

from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_ignore_empty=True,
        extra="ignore",
    )

    KAFKA_BOOTSTRAP_SERVERS: str = "kafka:9092"
    USER_SERVICE_URL: str = "http://user-service:8000"
    FIREBASE_CREDENTIALS_PATH: str = "/app/firebase-credentials.json"


@lru_cache()
def get_settings() -> Settings:
    return Settings()