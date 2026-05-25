# consumer.py

import json
import logging
import httpx
from aiokafka import AIOKafkaConsumer
from app.config import get_settings
from app.services.fcm import send_push

settings = get_settings()
logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)


async def start_consumer() -> None:
    logger.info("Starting Kafka consumer...")
    consumer = AIOKafkaConsumer(
        "meeting_request_created",
        bootstrap_servers=settings.KAFKA_BOOTSTRAP_SERVERS,
        group_id="notification-service",
    )
    await consumer.start()
    logger.info("Consumer started, waiting for messages...")
    async with httpx.AsyncClient() as client:
        try:
            async for msg in consumer:
                logger.info(f"Received message: {msg.value}")
                await handle_meeting_request(json.loads(msg.value), client)
        finally:
            await consumer.stop()


async def handle_meeting_request(data: dict, client: httpx.AsyncClient) -> None:
    creator_id = data["creator_id"]
    logger.info(f"Handling meeting request for creator_id={creator_id}")

    resp = await client.get(
        f"{settings.USER_SERVICE_URL}/users/{creator_id}",
        headers={"x-user-id": creator_id},
    )
    logger.info(f"User service response: {resp.status_code}")
    if resp.status_code != 200:
        return

    fcm_token = resp.json().get("fcm_token")
    logger.info(f"FCM token: {fcm_token}")
    if not fcm_token:
        return

    await send_push(
        fcm_token=fcm_token,
        title="Новая заявка",
        body="Кто-то хочет присоединиться к вашей активности",
    )