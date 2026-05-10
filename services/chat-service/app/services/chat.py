# chat.py

from uuid import UUID
from typing import List

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.message import Comment
from app.schemas.chat import CommentCreate


class CommentService:

    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_comments(self, activity_id: UUID) -> List[Comment]:
        result = await self.db.execute(
            select(Comment)
            .where(Comment.activity_id == activity_id)
            .order_by(Comment.created_at.asc())
        )
        return result.scalars().all()

    async def create_comment(
        self,
        activity_id: UUID,
        user_id: UUID,
        data: CommentCreate,
    ) -> Comment:
        comment = Comment(
            activity_id=activity_id,
            user_id=user_id,
            text=data.text,
        )
        self.db.add(comment)
        await self.db.commit()
        await self.db.refresh(comment)
        return comment

    async def delete_comment(self, comment_id: UUID, user_id: UUID) -> bool:
        result = await self.db.execute(
            select(Comment).where(
                Comment.id == comment_id,
                Comment.user_id == user_id,  # только свои
            )
        )
        comment = result.scalar_one_or_none()
        if not comment:
            return False
        await self.db.delete(comment)
        await self.db.commit()
        return True