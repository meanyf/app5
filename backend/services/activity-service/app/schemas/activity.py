import json
import uuid
from datetime import datetime

from pydantic import BaseModel, field_validator

from app.models.activity import ActivityStatus, ActivityType


class ActivityCreate(BaseModel):
    type: ActivityType
    title: str
    description: str | None = None
    address: str | None = None
    latitude: float | None = None
    longitude: float | None = None
    starts_at: datetime | None = None
    duration_minutes: int | None = None
    max_participants: int | None = None
    media_urls: list[str] = []


class ActivityOut(BaseModel):
    id: uuid.UUID
    owner_id: uuid.UUID
    type: ActivityType
    status: ActivityStatus
    title: str
    description: str | None
    address: str | None
    starts_at: datetime | None
    duration_minutes: int | None
    max_participants: int | None
    media_urls: list[str]
    created_at: datetime

    @field_validator("media_urls", mode="before")
    @classmethod
    def parse_media_urls(cls, v):
        if isinstance(v, str):
            return json.loads(v)
        return v or []

    model_config = {"from_attributes": True}


class ActivityUpdate(BaseModel):
    title: str | None = None
    description: str | None = None
    address: str | None = None
    starts_at: datetime | None = None
    duration_minutes: int | None = None
    max_participants: int | None = None
