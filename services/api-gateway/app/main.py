# main.py

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from starlette.middleware.base import BaseHTTPMiddleware

from app.proxy import lifespan
from app.middleware.jwt_validator import jwt_validator_middleware
from app.routers import activities, auth, chat, media, users, meetings
from prometheus_fastapi_instrumentator import Instrumentator  # 


app = FastAPI(title="API Gateway", lifespan=lifespan)

Instrumentator().instrument(app).expose(app)  

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
app.include_router(chat.router)
app.include_router(media.router)
app.include_router(users.router)
app.include_router(meetings.router)



@app.get("/")
def root():
    return {"message": "hello from backend"}


@app.get("/ping")
def ping():
    return {"status": "ok"}