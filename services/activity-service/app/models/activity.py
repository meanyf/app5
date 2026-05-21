# activity.py

import uuid
from datetime import datetime

from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from geoalchemy2 import Geography
from geoalchemy2.shape import to_shape

from app.db.base import Base


class Activity(Base):
    __tablename__ = "activities"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    type = Column(String, nullable=False)  # event | meeting
    creator_id = Column(String(36), nullable=False)    
    title = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    location = Column(Geography("POINT", srid=4326), nullable=False)
    starts_at = Column(DateTime, nullable=False)
    expires_at = Column(DateTime, nullable=False)
    max_participants = Column(Integer, nullable=True)
    status = Column(String, nullable=False, default="pending")  # pending | published | rejected

    media = relationship("ActivityMedia", back_populates="activity", lazy="selectin")

    @property
    def latitude(self) -> float:
        if self.location is None:
            return 0.0
        return to_shape(self.location).y

    @property
    def longitude(self) -> float:
        if self.location is None:
            return 0.0
        return to_shape(self.location).x


class ActivityMedia(Base):
    __tablename__ = "activity_media"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    activity_id = Column(
        UUID(as_uuid=True),
        ForeignKey("activities.id", ondelete="CASCADE"),
        nullable=False,
    )
    url = Column(String, nullable=False)
    type = Column(String, nullable=False)  # photo | video

    activity = relationship("Activity", back_populates="media")