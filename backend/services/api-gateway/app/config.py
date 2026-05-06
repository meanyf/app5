from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    jwt_secret: str
    jwt_algorithm: str = "HS256"

    redis_url: str = "redis://redis:6379/0"
    rate_limit_activities_per_day: int = 10

    auth_service_url: str = "http://auth-service:8000"
    user_service_url: str = "http://user-service:8000"
    activity_service_url: str = "http://activity-service:8000"
    media_service_url: str = "http://media-service:8000"
    chat_service_url: str = "http://chat-service:8000"

    class Config:
        env_file = ".env"


settings = Settings()
