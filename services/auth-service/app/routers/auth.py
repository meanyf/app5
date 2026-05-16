# auth.py

import logging

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.models.user_auth import UserAuth
from app.schemas.auth import SendOtpRequest, TokenResponse, VerifyOtpRequest
from app.services.jwt import create_access_token
from app.services.otp import send_otp, verify_otp

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/send-otp", status_code=status.HTTP_200_OK)
async def send_otp_handler(body: SendOtpRequest):
    """Генерирует OTP и отправляет СМС на указанный номер."""
    try:
        await send_otp(body.phone)
    except RuntimeError as e:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=str(e),
        )
    return {"detail": "Код отправлен"}


@router.post("/verify-otp", response_model=TokenResponse)
async def verify_otp_handler(
    body: VerifyOtpRequest,
    db: AsyncSession = Depends(get_db),
):
    """Проверяет OTP-код. При успехе возвращает JWT access-токен.
    Если пользователь не существует — регистрирует его автоматически.
    """
    is_valid = await verify_otp(body.phone, body.code)
    if not is_valid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Неверный или истёкший код",
        )

    # Upsert: найти или создать пользователя
    result = await db.execute(select(UserAuth).where(UserAuth.phone == body.phone))
    user = result.scalar_one_or_none()

    if user is None:
        user = UserAuth(phone=body.phone)
        db.add(user)
        await db.commit()
        await db.refresh(user)

    access_token = create_access_token(user_id=user.id, phone=user.phone)
    return TokenResponse(access_token=access_token)