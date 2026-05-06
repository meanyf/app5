import uuid
from datetime import datetime

from pydantic import BaseModel


class UserOut(BaseModel):
    id: uuid.UUID
    phone: str
    name: str | None
    bio: str | None
    avatar_url: str | None
    created_at: datetime

    model_config = {"from_attributes": True}


class UserUpdate(BaseModel):
    name: str | None = None
    bio: str | None = None
    avatar_url: str | None = None
