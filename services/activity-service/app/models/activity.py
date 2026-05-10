# activity.py

from datetime import datetime
import uuid

from sqlalchemy import Column, Integer, String, Text, DateTime
from sqlalchemy.dialects.postgresql import UUID
from geoalchemy2 import Geography
from geoalchemy2.shape import to_shape

from app.db.base import Base


class Activity(Base):
    __tablename__ = "activities"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    type = Column(String, nullable=False)  # event | meeting
    creator_id = Column(UUID(as_uuid=True), nullable=False)
    title = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    location = Column(Geography("POINT", srid=4326), nullable=False)
    starts_at = Column(DateTime, nullable=False)
    expires_at = Column(DateTime, nullable=False)

    max_participants = Column(Integer, nullable=True)


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