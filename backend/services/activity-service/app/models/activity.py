import enum
import uuid
from datetime import datetime

from geoalchemy2 import Geometry
from sqlalchemy import DateTime, Enum, ForeignKey, Integer, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class ActivityType(str, enum.Enum):
    event = "event"
    meeting = "meeting"


class ActivityStatus(str, enum.Enum):
    pending = "pending"
    published = "published"
    rejected = "rejected"
    finished = "finished"


class Activity(Base):
    __tablename__ = "activities"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    owner_id: Mapped[uuid.UUID] = mapped_column(nullable=False, index=True)
    type: Mapped[ActivityType] = mapped_column(Enum(ActivityType), nullable=False)
    status: Mapped[ActivityStatus] = mapped_column(
        Enum(ActivityStatus), nullable=False, default=ActivityStatus.pending
    )
    title: Mapped[str] = mapped_column(String(256), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    address: Mapped[str | None] = mapped_column(String(512), nullable=True)
    location: Mapped[object] = mapped_column(
        Geometry("POINT", srid=4326), nullable=True
    )
    starts_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    duration_minutes: Mapped[int | None] = mapped_column(Integer, nullable=True)
    max_participants: Mapped[int | None] = mapped_column(Integer, nullable=True)
    media_urls: Mapped[str | None] = mapped_column(Text, nullable=True)  # JSON list
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    participants: Mapped[list["Participant"]] = relationship(
        "Participant", back_populates="activity"
    )


class Participant(Base):
    __tablename__ = "participants"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    activity_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("activities.id"), nullable=False
    )
    user_id: Mapped[uuid.UUID] = mapped_column(nullable=False)
    status: Mapped[str] = mapped_column(
        String(20), default="pending"
    )  # pending/accepted/rejected
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    activity: Mapped["Activity"] = relationship(
        "Activity", back_populates="participants"
    )
