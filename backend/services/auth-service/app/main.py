from fastapi import FastAPI
from prometheus_fastapi_instrumentator import Instrumentator

from app.routers import auth

app = FastAPI(title="Auth Service", version="1.0.0")

Instrumentator().instrument(app).expose(app)

app.include_router(auth.router, tags=["auth"])


@app.get("/health")
async def health():
    return {"status": "ok"}
