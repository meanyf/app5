# activities.py

from fastapi import APIRouter, Request
from app.proxy import proxy_request
from app.config import get_settings

settings = get_settings()
router = APIRouter(prefix="/activities", tags=["activities"])


@router.api_route("/{path:path}", methods=["GET", "POST", "PUT", "PATCH", "DELETE"])
async def activities_proxy(path: str, request: Request):
    return await proxy_request(request, f"{settings.ACTIVITY_SERVICE_URL}/activities/{path}")