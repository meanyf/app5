# chat.py

from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Header
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.schemas.chat import CommentCreate, CommentRead
from app.services.chat import CommentService

router = APIRouter(prefix="/comments", tags=["comments"])


@router.get("/{activity_id}", response_model=list[CommentRead])
async def get_comments(
    activity_id: UUID,
    db: AsyncSession = Depends(get_db),
):
    service = CommentService(db)
    return await service.get_comments(activity_id)


@router.post("/{activity_id}", response_model=CommentRead, status_code=201)
async def create_comment(
    activity_id: UUID,
    comment_in: CommentCreate,
    db: AsyncSession = Depends(get_db),
    x_user_id: str = Header(...),
):
    service = CommentService(db)
    return await service.create_comment(activity_id, x_user_id, comment_in)

@router.delete("/{comment_id}", status_code=204)
async def delete_comment(
    comment_id: UUID,
    db: AsyncSession = Depends(get_db),
    # user_id: UUID = Depends(get_current_user)
):
    user_id = UUID("00000000-0000-0000-0000-000000000000")  # временно
    service = CommentService(db)
    deleted = await service.delete_comment(comment_id, user_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Comment not found")