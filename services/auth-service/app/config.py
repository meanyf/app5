# config.py

from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_ignore_empty=True,
        extra="ignore",
    )

    # Database
    AUTH_DATABASE_URL: str
    AUTH_DB_NAME: str = "auth_db"

    # Redis
    REDIS_URL: str

    # SMS.ru
    SMS_RU_API_ID: str

    # JWT
    JWT_SECRET: str
    JWT_ALGORITHM: str 
    JWT_EXPIRE_MINUTES: int 

    # OTP
    OTP_TTL_SECONDS: int = 300  # 5 минут


@lru_cache()
def get_settings() -> Settings:
    return Settings()