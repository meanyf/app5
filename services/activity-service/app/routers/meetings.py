# meetings.py

from fastapi import APIRouter, Depends, HTTPException, Header
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import get_db
from app.services.meeting import MeetingService
from app.schemas.meeting import MeetingRequestCreate, MeetingRequestRead, MeetingRequestUpdate

router = APIRouter(prefix="/meetings", tags=["meetings"])


@router.post("/", response_model=MeetingRequestRead)
async def create_request(
    body: MeetingRequestCreate,
    db: AsyncSession = Depends(get_db),
    x_user_id: str = Header(...),
):
    service = MeetingService(db)
    existing = await service.get_user_request(body.activity_id, x_user_id)
    if existing:
        raise HTTPException(status_code=400, detail="Already requested")
    return await service.create_request(body.activity_id, x_user_id)

@router.get("/activity/{activity_id}", response_model=list[MeetingRequestRead])
async def get_requests(
    activity_id: str,
    db: AsyncSession = Depends(get_db),
    x_user_id: str = Header(...),
):
    service = MeetingService(db)
    return await service.get_requests_for_activity(activity_id)

@router.patch("/{request_id}", response_model=MeetingRequestRead)
async def update_request(
    request_id: str,
    body: MeetingRequestUpdate,
    db: AsyncSession = Depends(get_db),
    x_user_id: str = Header(...),
):
    if body.status not in ("approved", "rejected"):
        raise HTTPException(status_code=400, detail="Invalid status")
    service = MeetingService(db)
    request = await service.update_status(request_id, body.status)
    if not request:
        raise HTTPException(status_code=404, detail="Not found")
    return request

@router.get("/my", response_model=list[MeetingRequestRead])
async def my_requests(
    db: AsyncSession = Depends(get_db),
    x_user_id: str = Header(...),
):
    service = MeetingService(db)
    return await service.get_requests_for_user(x_user_id)