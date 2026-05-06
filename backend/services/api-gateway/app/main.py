from fastapi import FastAPI
from prometheus_fastapi_instrumentator import Instrumentator

from app.middleware.rate_limit import RateLimitMiddleware
from app.routers import activities, auth, chat, media, users

app = FastAPI(title="API Gateway", version="1.0.0")

Instrumentator().instrument(app).expose(app)

app.add_middleware(RateLimitMiddleware)

app.include_router(auth.router, prefix="/auth", tags=["auth"])
app.include_router(users.router, prefix="/users", tags=["users"])
app.include_router(activities.router, prefix="/activities", tags=["activities"])
app.include_router(media.router, prefix="/media", tags=["media"])
app.include_router(chat.router, prefix="/chat", tags=["chat"])


@app.get("/health")
async def health():
    return {"status": "ok"}
