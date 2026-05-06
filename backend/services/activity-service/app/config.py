from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    activities_db_url: str
    kafka_bootstrap_servers: str = "kafka:9092"

    class Config:
        env_file = ".env"


settings = Settings()
