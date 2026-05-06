import httpx
from fastapi import APIRouter, Depends, Request

from app.config import settings
from app.dependencies import get_current_user

router = APIRouter()


@router.get("/{activity_id}/messages")
async def get_messages(
    activity_id: str,
    request: Request,
    current_user: dict = Depends(get_current_user),
):
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{settings.chat_service_url}/chat/{activity_id}/messages",
            headers={"X-User-ID": current_user["user_id"]},
            params=dict(request.query_params),
        )
    return response.json()
