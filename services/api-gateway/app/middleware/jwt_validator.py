# jwt_validator.py

import logging
from fastapi import Request, HTTPException, status
from jose import JWTError, jwt
from app.config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()

# Эндпоинты которые не требуют авторизации
PUBLIC_PATHS = {
    "/",
    "/ping",
    "/docs",
    "/openapi.json",
    "/auth/send-otp",
    "/auth/verify-otp",
    "/metrics", 
}


async def jwt_validator_middleware(request: Request, call_next):
    if request.method == "OPTIONS":
        return await call_next(request)
    if request.url.path in PUBLIC_PATHS:
        return await call_next(request)

    auth_header = request.headers.get("Authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Отсутствует токен авторизации",
        )

    token = auth_header.removeprefix("Bearer ").strip()

    try:
        payload = jwt.decode(
            token,
            settings.JWT_SECRET,
            algorithms=[settings.JWT_ALGORITHM],
        )
        user_id: str = payload.get("sub")
        phone: str = payload.get("phone", "")
        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Невалидный токен",
            )
    except JWTError as e:
        logger.warning("JWT validation failed: %s", e)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Невалидный или истёкший токен",
        )

    # Пробрасываем user_id во внутренние сервисы через заголовок
    request.state.user_id = user_id
    headers = dict(request.headers)
    headers["x-user-id"] = user_id
    headers["x-user-phone"] = phone

    # Мутируем scope чтобы заголовок был виден при проксировании
    request.scope["headers"] = [
        (k.lower().encode(), v.encode())
        for k, v in headers.items()
    ]

    return await call_next(request)