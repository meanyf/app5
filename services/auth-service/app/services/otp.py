# otp.py

import random
import logging

import httpx
import redis.asyncio as aioredis

from app.config import get_settings

logger = logging.getLogger(__name__)

settings = get_settings()

OTP_PREFIX = "otp:"

_redis_client: aioredis.Redis | None = None


def get_redis() -> aioredis.Redis:
    global _redis_client
    if _redis_client is None:
        _redis_client = aioredis.from_url(
            settings.REDIS_URL,
            encoding="utf-8",
            decode_responses=True,
        )
    return _redis_client


def _generate_code() -> str:
    return str(random.randint(100000, 999999))


async def send_otp(phone: str) -> None:
    """Генерирует OTP, сохраняет в Redis и отправляет через СМС.ру."""
    code = _generate_code()
    redis = get_redis()

    key = f"{OTP_PREFIX}{phone}"
    await redis.setex(key, settings.OTP_TTL_SECONDS, code)

    await _send_sms(phone, code)

async def _send_sms(phone: str, code: str) -> None:
    """Отправляет СМС через API СМС.ру."""
    url = "https://sms.ru/sms/send"
    params = {
        "api_id": settings.SMS_RU_API_ID,
        "to": phone,
        "msg": f"Ваш код подтверждения: {code}",
        "json": 1,
    }
    async with httpx.AsyncClient(timeout=10.0) as client:
        response = await client.get(url, params=params)

        print(response.text)

        response.raise_for_status()

        data = response.json()
        logger.info(data)

        print(data)

        # if data.get("status") != "OK":
        #     raise RuntimeError(
        #         f"Ошибка отправки СМС: {data.get('status_text', 'неизвестная ошибка')}"
        #     )

async def verify_otp(phone: str, code: str) -> bool:
    """Проверяет OTP-код. Возвращает True если код верный, удаляет его из Redis."""
    redis = get_redis()
    key = f"{OTP_PREFIX}{phone}"
    stored = await redis.get(key)

    if stored is None:
        return False  # Код истёк или не существует

    if stored != code:
        return False

    await redis.delete(key)
    return True