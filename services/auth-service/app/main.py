# main.py

from fastapi import FastAPI

from app.routers.auth import router as auth_router

app = FastAPI(title="Auth Service")

app.include_router(auth_router)


@app.get("/health")
async def health():
    return {"status": "ok"}