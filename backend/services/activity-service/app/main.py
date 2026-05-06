from contextlib import asynccontextmanager

from fastapi import FastAPI
from prometheus_fastapi_instrumentator import Instrumentator

from app.kafka_producer import close_producer, init_producer
from app.routers import activities


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_producer()
    yield
    await close_producer()


app = FastAPI(title="Activity Service", version="1.0.0", lifespan=lifespan)
Instrumentator().instrument(app).expose(app)
app.include_router(activities.router, prefix="/activities", tags=["activities"])


@app.get("/health")
async def health():
    return {"status": "ok"}
