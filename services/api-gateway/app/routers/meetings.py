# meetings.py

from fastapi import APIRouter, Request
from app.proxy import proxy_request
from app.config import get_settings

settings = get_settings()
router = APIRouter(prefix="/meetings", tags=["meetings"])

@router.api_route("/{path:path}", methods=["GET", "POST", "PUT", "PATCH", "DELETE"])
async def meetings_proxy(path: str, request: Request):
    return await proxy_request(request, f"{settings.ACTIVITY_SERVICE_URL}/meetings/{path}")