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
    CHAT_DATABASE_URL: str
    CHAT_DB_NAME: str = "chat_db"


@lru_cache()
def get_settings() -> Settings:
    return Settings()