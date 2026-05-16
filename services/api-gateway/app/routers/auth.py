# auth.py

from fastapi import APIRouter, Request
from app.proxy import proxy_request
from app.config import get_settings

settings = get_settings()
router = APIRouter(prefix="/auth", tags=["auth"])


@router.api_route("/{path:path}", methods=["GET", "POST"])
async def auth_proxy(path: str, request: Request):
    return await proxy_request(request, f"{settings.AUTH_SERVICE_URL}/auth/{path}")