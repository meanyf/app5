# dependencies.py

from fastapi import Header, HTTPException
from uuid import UUID

async def get_current_user(x_user_id: str = Header(None)) -> UUID:
    if not x_user_id:
        raise HTTPException(status_code=401, detail="Unauthorized")
    return UUID(x_user_id)