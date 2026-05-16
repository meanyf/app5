# main.py

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from starlette.middleware.base import BaseHTTPMiddleware

from app.proxy import lifespan
from app.middleware.jwt_validator import jwt_validator_middleware
from app.routers import activities, auth

app = FastAPI(title="API Gateway", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.add_middleware(BaseHTTPMiddleware, dispatch=jwt_validator_middleware)

app.include_router(activities.router)
app.include_router(auth.router)


@app.get("/")
def root():
    return {"message": "hello from backend"}


@app.get("/ping")
def ping():
    return {"status": "ok"}