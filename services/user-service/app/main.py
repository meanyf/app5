# main.py

from fastapi import FastAPI
from app.routers.users import router as users_router

app = FastAPI(title="User Service")

app.include_router(users_router)


@app.get("/health")
async def health():
    return {"status": "ok"}