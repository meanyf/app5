import redis.asyncio as aioredis
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import JSONResponse

from app.config import settings


class RateLimitMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        if request.method == "POST" and request.url.path.startswith("/activities"):
            user_id = request.headers.get("X-User-ID")
            if user_id:
                r = aioredis.from_url(settings.redis_url)
                key = f"rate:activities:{user_id}"
                count = await r.incr(key)
                if count == 1:
                    await r.expire(key, 86400)
                await r.aclose()
                if count > settings.rate_limit_activities_per_day:
                    return JSONResponse(
                        status_code=429,
                        content={"detail": "Activity creation limit reached for today"},
                    )
        return await call_next(request)
