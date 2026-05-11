# activity.py

from pydantic import BaseModel, model_validator, field_validator
from datetime import datetime, timezone
from uuid import UUID
from typing import Literal, Optional


def _to_naive_utc(dt: datetime) -> datetime:
    if dt.tzinfo is not None:
        return dt.astimezone(timezone.utc).replace(tzinfo=None)
    return dt


# ── медиа ─────────────────────────────────────────────────────────────────────

class MediaItem(BaseModel):
    url: str
    type: Literal["photo", "video"]


class MediaItemRead(BaseModel):
    id: UUID
    url: str
    type: Literal["photo", "video"]

    class Config:
        from_attributes = True


# ── активность ────────────────────────────────────────────────────────────────

class ActivityCreate(BaseModel):
    type: Literal["event", "meeting"]
    title: str
    description: Optional[str] = None
    latitude: float
    longitude: float
    starts_at: datetime
    expires_at: datetime
    max_participants: Optional[int] = None
    media: list[MediaItem] = []  # список {url, type} которые вернул media-service

    @field_validator("starts_at", "expires_at", mode="after")
    @classmethod
    def normalize_dt(cls, v: datetime) -> datetime:
        return _to_naive_utc(v)


class ActivityUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    starts_at: Optional[datetime] = None
    expires_at: Optional[datetime] = None
    max_participants: Optional[int] = None

    @field_validator("starts_at", "expires_at", mode="after")
    @classmethod
    def normalize_dt(cls, v: Optional[datetime]) -> Optional[datetime]:
        if v is None:
            return v
        return _to_naive_utc(v)

    @model_validator(mode='after')
    def coords_both_or_neither(self):
        has_lat = self.latitude is not None
        has_lng = self.longitude is not None
        if has_lat != has_lng:
            raise ValueError('latitude и longitude должны передаваться вместе')
        return self


class ActivityRead(BaseModel):
    id: UUID
    type: Literal["event", "meeting"]
    creator_id: UUID
    title: str
    description: Optional[str] = None
    latitude: float
    longitude: float
    starts_at: datetime
    expires_at: datetime
    max_participants: Optional[int] = None
    media: list[MediaItemRead] = []

    class Config:
        from_attributes = True