# config.py

from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache

class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",          
        env_ignore_empty=True,
        extra="ignore"
    )

    # Database settings для activity-service
    ACTIVITY_DATABASE_URL: str
    ACTIVITY_DB_NAME: str = "activity_db"

    # Дополнительно (можно использовать)
    POSTGRES_HOST: str = "postgres-activity"
    POSTGRES_PORT: int = 5432
    POSTGRES_USER: str = "postgres"
    POSTGRES_PASSWORD: str = "postgres123"


@lru_cache()
def get_settings() -> Settings:
    return Settings()