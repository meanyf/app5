import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.auth import RefreshToken, User
from app.schemas.auth import (
    RefreshRequest,
    SendOTPRequest,
    SendOTPResponse,
    TokenResponse,
    VerifyOTPRequest,
)
from app.services import jwt as jwt_service
from app.services import otp as otp_service

router = APIRouter()


@router.post("/send-otp", response_model=SendOTPResponse)
async def send_otp(body: SendOTPRequest):
    await otp_service.generate_and_send_otp(body.phone)
    return SendOTPResponse(message="OTP sent")


@router.post("/verify-otp", response_model=TokenResponse)
async def verify_otp(body: VerifyOTPRequest, db: AsyncSession = Depends(get_db)):
    valid = await otp_service.verify_otp(body.phone, body.code)
    if not valid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid or expired OTP"
        )

    result = await db.execute(select(User).where(User.phone == body.phone))
    user = result.scalar_one_or_none()
    if not user:
        user = User(id=uuid.uuid4(), phone=body.phone)
        db.add(user)
        await db.commit()
        await db.refresh(user)

    access_token = jwt_service.create_access_token(str(user.id))
    refresh_token, expires_at = jwt_service.create_refresh_token(str(user.id))

    db.add(RefreshToken(user_id=user.id, token=refresh_token, expires_at=expires_at))
    await db.commit()

    return TokenResponse(access_token=access_token, refresh_token=refresh_token)


@router.post("/refresh", response_model=TokenResponse)
async def refresh(body: RefreshRequest, db: AsyncSession = Depends(get_db)):
    try:
        payload = jwt_service.decode_token(body.refresh_token)
        if payload.get("type") != "refresh":
            raise ValueError
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid refresh token"
        )

    result = await db.execute(
        select(RefreshToken).where(RefreshToken.token == body.refresh_token)
    )
    token_obj = result.scalar_one_or_none()
    if not token_obj:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Token not found"
        )

    await db.delete(token_obj)
    await db.commit()

    user_id = payload["sub"]
    access_token = jwt_service.create_access_token(user_id)
    new_refresh_token, expires_at = jwt_service.create_refresh_token(user_id)

    db.add(
        RefreshToken(
            user_id=uuid.UUID(user_id), token=new_refresh_token, expires_at=expires_at
        )
    )
    await db.commit()

    return TokenResponse(access_token=access_token, refresh_token=new_refresh_token)
