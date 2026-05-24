# activities.py

from fastapi import APIRouter, Depends, HTTPException, Header
from sqlalchemy.ext.asyncio import AsyncSession
from uuid import UUID

from app.db.session import get_db
from app.schemas.activity import ActivityCreate, ActivityRead, ActivityUpdate
from app.services.activity import ActivityService

router = APIRouter(prefix="/activities", tags=["activities"])

import logging
logger = logging.getLogger(__name__)

@router.post("/", response_model=ActivityRead, status_code=201)
async def create_activity(
    activity_in: ActivityCreate,
    db: AsyncSession = Depends(get_db),
    x_user_id: str = Header(...),
):
    service = ActivityService(db)
    return await service.create_activity(x_user_id, activity_in)


@router.get("/", response_model=list[ActivityRead])
async def get_activities(
    db: AsyncSession = Depends(get_db),
    creator_id: str | None = None,
    activity_type: str | None = None,
):
    service = ActivityService(db)
    activities = await service.get_activities(creator_id=creator_id, activity_type=activity_type)
    logger.info("Activities: %s", [a.id for a in activities])
    return activities

@router.get("/{activity_id}", response_model=ActivityRead)
async def get_activity(activity_id: UUID, db: AsyncSession = Depends(get_db)):
    service = ActivityService(db)
    activity = await service.get_activity(activity_id)
    if not activity:
        raise HTTPException(status_code=404, detail="Activity not found")
    return activity


@router.patch("/{activity_id}", response_model=ActivityRead)
async def update_activity(
    activity_id: UUID,
    activity_in: ActivityUpdate,
    db: AsyncSession = Depends(get_db),
    # current_user_id: UUID = Depends(get_current_user)
):
    service = ActivityService(db)
    activity = await service.update_activity(activity_id, activity_in)
    if not activity:
        raise HTTPException(status_code=404, detail="Activity not found")
    return activity


@router.delete("/{activity_id}", status_code=204)
async def delete_activity(
    activity_id: UUID,
    db: AsyncSession = Depends(get_db),
    # current_user_id: UUID = Depends(get_current_user)
):
    service = ActivityService(db)
    deleted = await service.delete_activity(activity_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Activity not found")