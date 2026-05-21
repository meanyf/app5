# message.py

import uuid
from datetime import datetime

from sqlalchemy import Column, Text, DateTime, String
from sqlalchemy.dialects.postgresql import UUID

from app.db.base import Base


class Comment(Base):
    __tablename__ = "comments"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    activity_id = Column(UUID(as_uuid=True), nullable=False, index=True)
    user_id = Column(String(36), nullable=False)
    text = Column(Text, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)