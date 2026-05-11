# minio.py

import uuid
from miniopy_async import Minio

from app.config import get_settings

settings = get_settings()

_client: Minio | None = None


def get_minio() -> Minio:
    global _client
    if _client is None:
        _client = Minio(
            endpoint=settings.MINIO_ENDPOINT,
            access_key=settings.MINIO_ACCESS_KEY,
            secret_key=settings.MINIO_SECRET_KEY,
            secure=settings.MINIO_USE_SSL,
        )
    return _client


async def ensure_bucket():
    import json
    client = get_minio()
    exists = await client.bucket_exists(settings.MINIO_BUCKET)
    if not exists:
        await client.make_bucket(settings.MINIO_BUCKET)
    
    policy = {
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow",
            "Principal": {"AWS": ["*"]},
            "Action": ["s3:GetObject"],
            "Resource": [f"arn:aws:s3:::{settings.MINIO_BUCKET}/*"]
        }]
    }
    await client.set_bucket_policy(settings.MINIO_BUCKET, json.dumps(policy))

async def upload_file(data: bytes, content_type: str, extension: str) -> str:
    """Загружает файл в MinIO, возвращает url."""
    import io

    client = get_minio()
    file_name = f"{uuid.uuid4()}{extension}"

    await client.put_object(
        bucket_name=settings.MINIO_BUCKET,
        object_name=file_name,
        data=io.BytesIO(data),
        length=len(data),
        content_type=content_type,
    )

    # публичный url
    url = f"{settings.MINIO_PUBLIC_URL}/{settings.MINIO_BUCKET}/{file_name}"
    return url, file_name