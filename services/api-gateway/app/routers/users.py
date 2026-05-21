# users.py

from fastapi import APIRouter, Request
from app.proxy import proxy_request
from app.config import get_settings

settings = get_settings()
router = APIRouter(prefix="/users", tags=["users"])


@router.api_route("/{path:path}", methods=["GET", "POST", "PATCH", "DELETE"])
async def users_proxy(path: str, request: Request):
    return await proxy_request(request, f"{settings.USER_SERVICE_URL}/users/{path}")