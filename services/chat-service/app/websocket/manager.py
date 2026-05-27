# manager.py

import logging
from fastapi import WebSocket

logger = logging.getLogger(__name__)


class ConnectionManager:
    def __init__(self):
        self.rooms: dict[str, list[WebSocket]] = {}

    async def connect(self, room_id: str, websocket: WebSocket) -> None:
        await websocket.accept()
        if room_id not in self.rooms:
            self.rooms[room_id] = []
        self.rooms[room_id].append(websocket)
        logger.info("Client connected to room %s, total: %d", room_id, len(self.rooms[room_id]))

    def disconnect(self, room_id: str, websocket: WebSocket) -> None:
        if room_id in self.rooms:
            self.rooms[room_id].remove(websocket)
            if not self.rooms[room_id]:
                del self.rooms[room_id]
        logger.info("Client disconnected from room %s", room_id)

    async def broadcast(self, room_id: str, message: dict) -> None:
        if room_id not in self.rooms:
            return
        disconnected = []
        for websocket in self.rooms[room_id]:
            try:
                await websocket.send_json(message)
            except Exception:
                disconnected.append(websocket)
        for websocket in disconnected:
            self.disconnect(room_id, websocket)


manager = ConnectionManager()