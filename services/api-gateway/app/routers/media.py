# media.py

from fastapi import APIRouter, Request
from app.proxy import proxy_request
from app.config import get_settings

settings = get_settings()
router = APIRouter(prefix="/media", tags=["media"])


@router.api_route("/{path:path}", methods=["GET", "POST", "PUT", "PATCH", "DELETE"])
async def media_proxy(path: str, request: Request):
    return await proxy_request(request, f"{settings.MEDIA_SERVICE_URL}/media/{path}")