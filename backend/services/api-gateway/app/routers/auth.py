import httpx
from fastapi import APIRouter, Request

from app.config import settings

router = APIRouter()


@router.post("/send-otp")
async def send_otp(request: Request):
    body = await request.body()
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{settings.auth_service_url}/send-otp",
            content=body,
            headers={"Content-Type": "application/json"},
        )
    return response.json()


@router.post("/verify-otp")
async def verify_otp(request: Request):
    body = await request.body()
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{settings.auth_service_url}/verify-otp",
            content=body,
            headers={"Content-Type": "application/json"},
        )
    return response.json()


@router.post("/refresh")
async def refresh_token(request: Request):
    body = await request.body()
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{settings.auth_service_url}/refresh",
            content=body,
            headers={"Content-Type": "application/json"},
        )
    return response.json()
