# user.py

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User
from app.schemas.user import UserUpdate


class UserService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_or_create(self, user_id: str, phone: str) -> User:
        result = await self.db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()

        if user is None:
            user = User(id=user_id, phone=phone)
            self.db.add(user)
            await self.db.commit()
            await self.db.refresh(user)

        return user

    async def get_by_id(self, user_id: str) -> User | None:
        result = await self.db.execute(select(User).where(User.id == user_id))
        return result.scalar_one_or_none()

    async def update(self, user: User, data: UserUpdate) -> User:
        if data.name is not None:
            user.name = data.name
        if data.avatar_url is not None:
            user.avatar_url = data.avatar_url
        if data.description is not None:
            user.description = data.description
        if data.fcm_token is not None:  # добавить
            user.fcm_token = data.fcm_token
        await self.db.commit()
        await self.db.refresh(user)
        return user
    


    async def get_by_ids(self, ids: list[str]) -> list[User]:
        result = await self.db.execute(
            select(User).where(User.id.in_(ids))
        )
        return result.scalars().all()