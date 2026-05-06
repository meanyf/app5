import random

import httpx
import redis.asyncio as aioredis

from app.config import settings

OTP_PREFIX = "otp:"


async def generate_and_send_otp(phone: str) -> None:
    code = str(random.randint(100000, 999999))
    r = aioredis.from_url(settings.redis_url)
    await r.setex(f"{OTP_PREFIX}{phone}", settings.otp_ttl_seconds, code)
    await r.aclose()
    await _send_sms(phone, code)


async def verify_otp(phone: str, code: str) -> bool:
    r = aioredis.from_url(settings.redis_url)
    stored = await r.get(f"{OTP_PREFIX}{phone}")
    if stored and stored.decode() == code:
        await r.delete(f"{OTP_PREFIX}{phone}")
        await r.aclose()
        return True
    await r.aclose()
    return False


async def _send_sms(phone: str, code: str) -> None:
    url = "https://sms.ru/sms/send"
    params = {
        "api_id": settings.smsru_api_key,
        "to": phone,
        "msg": f"Your verification code: {code}",
        "json": 1,
    }
    async with httpx.AsyncClient() as client:
        await client.get(url, params=params)
