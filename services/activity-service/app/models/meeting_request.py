# meeting_request.py

import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from app.db.base import Base

class MeetingRequest(Base):
    __tablename__ = "meeting_requests"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    activity_id = Column(UUID(as_uuid=True), ForeignKey("activities.id"), nullable=False)
    user_id = Column(String, nullable=False)
    status = Column(String, default="pending")  # pending, approved, rejected
    created_at = Column(DateTime, default=datetime.utcnow)