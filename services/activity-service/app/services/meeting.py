# meeting.py

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from uuid import UUID as PyUUID
from app.models.meeting_request import MeetingRequest

class MeetingService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create_request(self, activity_id: str, user_id: str) -> MeetingRequest:
        request = MeetingRequest(activity_id=PyUUID(activity_id), user_id=user_id)
        self.db.add(request)
        await self.db.commit()
        await self.db.refresh(request)
        return request

    async def get_requests_for_activity(self, activity_id: str) -> list[MeetingRequest]:
        result = await self.db.execute(
            select(MeetingRequest).where(MeetingRequest.activity_id == PyUUID(activity_id))
        )
        return result.scalars().all()

    async def get_requests_for_user(self, user_id: str) -> list[MeetingRequest]:
        result = await self.db.execute(
            select(MeetingRequest).where(MeetingRequest.user_id == user_id)
        )
        return result.scalars().all()

    async def update_status(self, request_id: str, status: str) -> MeetingRequest | None:
        result = await self.db.execute(
            select(MeetingRequest).where(MeetingRequest.id == request_id)
        )
        request = result.scalar_one_or_none()
        if not request:
            return None
        request.status = status
        await self.db.commit()
        await self.db.refresh(request)
        return request

    async def get_user_request(self, activity_id: str, user_id: str) -> MeetingRequest | None:
        result = await self.db.execute(
            select(MeetingRequest).where(
                MeetingRequest.activity_id == PyUUID(activity_id),
                MeetingRequest.user_id == user_id,
            )
        )
        return result.scalar_one_or_none()