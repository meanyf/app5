from fastapi import FastAPI
from prometheus_fastapi_instrumentator import Instrumentator

from app.routers import users

app = FastAPI(title="User Service", version="1.0.0")
Instrumentator().instrument(app).expose(app)
app.include_router(users.router, prefix="/users", tags=["users"])


@app.get("/health")
async def health():
    return {"status": "ok"}
