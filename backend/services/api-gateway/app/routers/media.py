import httpx
from fastapi import APIRouter, Depends, File, Request, UploadFile

from app.config import settings
from app.dependencies import get_current_user

router = APIRouter()


@router.post("/upload")
async def upload_media(
    file: UploadFile = File(...),
    current_user: dict = Depends(get_current_user),
):
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{settings.media_service_url}/upload",
            files={"file": (file.filename, await file.read(), file.content_type)},
            headers={"X-User-ID": current_user["user_id"]},
        )
    return response.json()
