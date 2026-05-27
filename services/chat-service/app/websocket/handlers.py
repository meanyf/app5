# handlers.py

from fastapi import WebSocket, WebSocketDisconnect
from sqlalchemy.ext.asyncio import AsyncSession
from app.websocket.manager import manager
from app.services.chat import CommentService
from app.schemas.chat import CommentCreate


async def websocket_handler(
    websocket: WebSocket,
    activity_id: str,
    user_id: str,
    db: AsyncSession,
) -> None:
    await manager.connect(activity_id, websocket)
    try:
        while True:
            data = await websocket.receive_json()
            text = data.get("text", "").strip()
            if not text:
                continue

            service = CommentService(db)
            comment = await service.create_comment_ws(
                activity_id=activity_id,
                user_id=user_id,
                text=text,
            )

            await manager.broadcast(activity_id, {
                "id": str(comment.id),
                "user_id": str(comment.user_id),
                "text": comment.text,
                "created_at": comment.created_at.isoformat(),
            })
    except WebSocketDisconnect:
        manager.disconnect(activity_id, websocket)