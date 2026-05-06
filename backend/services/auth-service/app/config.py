from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    auth_db_url: str
    redis_url: str = "redis://redis:6379/0"

    jwt_secret: str
    jwt_algorithm: str = "HS256"
    jwt_access_expire_minutes: int = 30
    jwt_refresh_expire_days: int = 30

    smsru_api_key: str
    otp_ttl_seconds: int = 300

    class Config:
        env_file = ".env"


settings = Settings()
