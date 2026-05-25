# fcm.py

import firebase_admin
from firebase_admin import credentials, messaging
from app.config import get_settings

settings = get_settings()

_app = None

def get_firebase_app():
    global _app
    if _app is None:
        cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
        _app = firebase_admin.initialize_app(cred)
    return _app


async def send_push(fcm_token: str, title: str, body: str) -> None:
    get_firebase_app()
    message = messaging.Message(
        notification=messaging.Notification(title=title, body=body),
        token=fcm_token,
    )
    messaging.send(message)