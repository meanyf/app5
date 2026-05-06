import httpx
from fastapi import APIRouter, Depends, Request

from app.config import settings
from app.dependencies import get_current_user

router = APIRouter()


@router.get("/me")
async def get_me(request: Request, current_user: dict = Depends(get_current_user)):
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{settings.user_service_url}/users/{current_user['user_id']}",
        )
    return response.json()


@router.patch("/me")
async def update_me(request: Request, current_user: dict = Depends(get_current_user)):
    body = await request.body()
    async with httpx.AsyncClient() as client:
        response = await client.patch(
            f"{settings.user_service_url}/users/{current_user['user_id']}",
            content=body,
            headers={"Content-Type": "application/json"},
        )
    return response.json()
