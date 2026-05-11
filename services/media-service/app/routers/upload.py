# upload.py

import os
from fastapi import APIRouter, HTTPException, UploadFile, File

from app.services.minio import upload_file
from app.kafka.producer import publish_video_uploaded

router = APIRouter(prefix="/media", tags=["media"])

ALLOWED_PHOTO = {".jpg", ".jpeg", ".png", ".webp"}
ALLOWED_VIDEO = {".mp4", ".mov", ".avi"}
MAX_PHOTO_MB = 10
MAX_VIDEO_MB = 100


@router.post("/upload")
async def upload_media(file: UploadFile = File(...)):
    ext = os.path.splitext(file.filename or "")[1].lower()

    if ext in ALLOWED_PHOTO:
        media_type = "photo"
        max_mb = MAX_PHOTO_MB
    elif ext in ALLOWED_VIDEO:
        media_type = "video"
        max_mb = MAX_VIDEO_MB
    else:
        raise HTTPException(
            status_code=400,
            detail=f"Недопустимый формат файла. Разрешены: {ALLOWED_PHOTO | ALLOWED_VIDEO}",
        )

    data = await file.read()
    size_mb = len(data) / (1024 * 1024)
    if size_mb > max_mb:
        raise HTTPException(
            status_code=400,
            detail=f"Файл слишком большой. Максимум {max_mb}MB",
        )

    url, file_name = await upload_file(data, file.content_type, ext)

    # видео отправляем на обработку через Kafka
    if media_type == "video":
        await publish_video_uploaded(file_name, url)

    return {
        "url": url,
        "type": media_type,
        "file_name": file_name,
    }