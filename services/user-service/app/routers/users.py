# users.py

from fastapi import APIRouter, Depends, Header, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.schemas.user import UserRead, UserUpdate
from app.services.user import UserService

router = APIRouter(prefix="/users", tags=["users"])


@router.get("/me", response_model=UserRead)
async def get_me(
    db: AsyncSession = Depends(get_db),
    x_user_id: str = Header(...),
    x_user_phone: str = Header(""),
):
    service = UserService(db)
    user = await service.get_or_create(x_user_id, x_user_phone)
    return user


@router.patch("/me", response_model=UserRead)
async def update_me(
    data: UserUpdate,
    db: AsyncSession = Depends(get_db),
    x_user_id: str = Header(...),
    x_user_phone: str = Header(""),
):
    service = UserService(db)
    user = await service.get_or_create(x_user_id, x_user_phone)
    return await service.update(user, data)


@router.get("/{user_id}", response_model=UserRead)
async def get_user(
    user_id: str,
    db: AsyncSession = Depends(get_db),
    x_user_id: str = Header(...),  # просто чтобы эндпоинт был закрыт
):
    service = UserService(db)
    user = await service.get_by_id(user_id)
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Пользователь не найден")
    return user