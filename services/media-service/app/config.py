# config.py

from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_ignore_empty=True,
        extra="ignore",
    )

    MINIO_ENDPOINT: str = "minio:9000"
    MINIO_ACCESS_KEY: str = "minioadmin"
    MINIO_SECRET_KEY: str = "minioadmin"
    MINIO_BUCKET: str = "media"
    MINIO_USE_SSL: bool = False

    KAFKA_BOOTSTRAP_SERVERS: str = "kafka:9092"
    MINIO_PUBLIC_URL: str = "http://192.168.0.124:9000"


@lru_cache()
def get_settings() -> Settings:
    return Settings()