# activity.py

from pydantic import BaseModel, model_validator
from datetime import datetime
from uuid import UUID
from typing import Literal, Optional


class ActivityCreate(BaseModel):
    type: Literal["event", "meeting"]
    title: str
    description: Optional[str] = None
    latitude: float
    longitude: float
    starts_at: datetime
    expires_at: datetime


class ActivityUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    starts_at: Optional[datetime] = None
    expires_at: Optional[datetime] = None

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

    class Config:
        from_attributes = True