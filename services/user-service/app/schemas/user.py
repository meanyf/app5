# user.py

from pydantic import BaseModel
from datetime import datetime


class UserRead(BaseModel):
    id: str
    phone: str
    name: str | None
    avatar_url: str | None
    created_at: datetime

    model_config = {"from_attributes": True}


class UserUpdate(BaseModel):
    name: str | None = None
    avatar_url: str | None = None