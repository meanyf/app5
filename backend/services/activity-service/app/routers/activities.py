import json
import uuid

from fastapi import APIRouter, Depends, Header, HTTPException, Query, status
from geoalchemy2.functions import ST_DWithin, ST_MakePoint, ST_SetSRID
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.kafka_producer import publish
from app.models.activity import Activity, ActivityStatus, Participant
from app.schemas.activity import ActivityCreate, ActivityOut, ActivityUpdate

router = APIRouter()


@router.get("", response_model=list[ActivityOut])
async def list_activities(
    lat: float | None = Query(None),
    lon: float | None = Query(None),
    radius_km: float = Query(10.0),
    db: AsyncSession = Depends(get_db),
):
    q = select(Activity).where(Activity.status == ActivityStatus.published)
    if lat is not None and lon is not None:
        point = ST_SetSRID(ST_MakePoint(lon, lat), 4326)
        q = q.where(ST_DWithin(Activity.location, point, radius_km * 1000))
    result = await db.execute(q)
    return result.scalars().all()


@router.post("", response_model=ActivityOut, status_code=status.HTTP_201_CREATED)
async def create_activity(
    body: ActivityCreate,
    x_user_id: str = Header(...),
    db: AsyncSession = Depends(get_db),
):
    location = None
    if body.latitude is not None and body.longitude is not None:
        location = f"SRID=4326;POINT({body.longitude} {body.latitude})"

    activity = Activity(
        owner_id=uuid.UUID(x_user_id),
        type=body.type,
        title=body.title,
        description=body.description,
        address=body.address,
        location=location,
        starts_at=body.starts_at,
        duration_minutes=body.duration_minutes,
        max_participants=body.max_participants,
        media_urls=json.dumps(body.media_urls),
    )
    db.add(activity)
    await db.commit()
    await db.refresh(activity)

    await publish(
        "activity.created",
        {"activity_id": str(activity.id), "owner_id": str(activity.owner_id)},
    )

    return activity


@router.get("/{activity_id}", response_model=ActivityOut)
async def get_activity(activity_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Activity).where(Activity.id == activity_id))
    activity = result.scalar_one_or_none()
    if not activity:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Activity not found"
        )
    return activity


@router.patch("/{activity_id}", response_model=ActivityOut)
async def update_activity(
    activity_id: uuid.UUID,
    body: ActivityUpdate,
    x_user_id: str = Header(...),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Activity).where(Activity.id == activity_id))
    activity = result.scalar_one_or_none()
    if not activity:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Activity not found"
        )
    if str(activity.owner_id) != x_user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")
    for field, value in body.model_dump(exclude_unset=True).items():
        setattr(activity, field, value)
    await db.commit()
    await db.refresh(activity)
    return activity


@router.delete("/{activity_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_activity(
    activity_id: uuid.UUID,
    x_user_id: str = Header(...),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Activity).where(Activity.id == activity_id))
    activity = result.scalar_one_or_none()
    if not activity:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Activity not found"
        )
    if str(activity.owner_id) != x_user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")
    await db.delete(activity)
    await db.commit()


@router.post("/{activity_id}/join", status_code=status.HTTP_201_CREATED)
async def join_activity(
    activity_id: uuid.UUID,
    x_user_id: str = Header(...),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Activity).where(Activity.id == activity_id))
    activity = result.scalar_one_or_none()
    if not activity:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Activity not found"
        )

    participant = Participant(activity_id=activity_id, user_id=uuid.UUID(x_user_id))
    db.add(participant)
    await db.commit()

    await publish(
        "meeting.request.updated",
        {
            "activity_id": str(activity_id),
            "user_id": x_user_id,
            "status": "pending",
        },
    )
    return {"message": "Join request submitted"}
