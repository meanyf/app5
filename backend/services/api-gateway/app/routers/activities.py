import httpx
from fastapi import APIRouter, Depends, Request

from app.config import settings
from app.dependencies import get_current_user

router = APIRouter()


@router.get("")
async def list_activities(request: Request):
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{settings.activity_service_url}/activities",
            params=dict(request.query_params),
        )
    return response.json()


@router.post("")
async def create_activity(
    request: Request, current_user: dict = Depends(get_current_user)
):
    body = await request.body()
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{settings.activity_service_url}/activities",
            content=body,
            headers={
                "Content-Type": "application/json",
                "X-User-ID": current_user["user_id"],
            },
        )
    return response.json()


@router.get("/{activity_id}")
async def get_activity(activity_id: str, request: Request):
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{settings.activity_service_url}/activities/{activity_id}",
        )
    return response.json()


@router.patch("/{activity_id}")
async def update_activity(
    activity_id: str, request: Request, current_user: dict = Depends(get_current_user)
):
    body = await request.body()
    async with httpx.AsyncClient() as client:
        response = await client.patch(
            f"{settings.activity_service_url}/activities/{activity_id}",
            content=body,
            headers={
                "Content-Type": "application/json",
                "X-User-ID": current_user["user_id"],
            },
        )
    return response.json()


@router.delete("/{activity_id}")
async def delete_activity(
    activity_id: str, request: Request, current_user: dict = Depends(get_current_user)
):
    async with httpx.AsyncClient() as client:
        response = await client.delete(
            f"{settings.activity_service_url}/activities/{activity_id}",
            headers={"X-User-ID": current_user["user_id"]},
        )
    return response.json()


@router.post("/{activity_id}/join")
async def join_activity(
    activity_id: str, request: Request, current_user: dict = Depends(get_current_user)
):
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{settings.activity_service_url}/activities/{activity_id}/join",
            headers={"X-User-ID": current_user["user_id"]},
        )
    return response.json()
