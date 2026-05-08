# activity.py

from typing import List, Optional
from uuid import UUID
from datetime import datetime

from sqlalchemy import select, delete
from sqlalchemy.ext.asyncio import AsyncSession
from geoalchemy2 import WKTElement

from app.models.activity import Activity
from app.schemas.activity import ActivityCreate, ActivityRead, ActivityUpdate


class ActivityService:
	
	def __init__(self, db: AsyncSession):
		self.db = db

	async def create_activity(
		self, 
		creator_id: UUID, 
		data: ActivityCreate
	) -> Activity:
		location = WKTElement(
			f"POINT({data.longitude} {data.latitude})", 
			srid=4326
		)

		activity = Activity(
			type=data.type,
			creator_id=creator_id,
			title=data.title,
			description=data.description,
			location=location,
			starts_at=data.starts_at,
			expires_at=data.expires_at,
		)
		self.db.add(activity)
		await self.db.commit()
		await self.db.refresh(activity)
		return activity


	async def get_activity(self, activity_id: UUID) -> Optional[Activity]:
		result = await self.db.execute(
			select(Activity).where(Activity.id == activity_id)
		)
		return result.scalar_one_or_none()


	async def get_activities(
		self, 
	) -> List[Activity]:
		result = await self.db.execute(
			select(Activity)
			.order_by(Activity.starts_at.desc())
		)
		return result.scalars().all()


	async def delete_activity(self, activity_id: UUID) -> bool:
		result = await self.db.execute(
			delete(Activity).where(Activity.id == activity_id)
		)
		await self.db.commit()
		return result.rowcount > 0


	async def update_activity(
		self, 
		activity_id: UUID, 
		data: ActivityUpdate
	) -> Optional[Activity]:
		activity = await self.get_activity(activity_id)
		if not activity:
			return None

		update_data = data.model_dump(exclude_unset=True)

		# Обработка изменения координат
		if "latitude" in update_data and "longitude" in update_data:
			location = WKTElement(
				f"POINT({update_data.pop('longitude')} {update_data.pop('latitude')})", 
				srid=4326
			)
			activity.location = location

		for field, value in update_data.items():
			setattr(activity, field, value)

		await self.db.commit()
		await self.db.refresh(activity)
		return activity