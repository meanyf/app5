# chat.py

from pydantic import BaseModel
from datetime import datetime
from uuid import UUID


class CommentCreate(BaseModel):
    text: str
    # user_id сюда не кладём — будет браться из JWT когда подключишь авторизацию


class CommentRead(BaseModel):
    id: UUID
    activity_id: UUID
    user_id: str
    text: str
    created_at: datetime

    class Config:
        from_attributes = True