# consumer.py

import asyncio
import json
import logging

from aiokafka import AIOKafkaConsumer

from app.config import get_settings
from app.db.session import AsyncSessionLocal
from app.services.activity import ActivityService

logger = logging.getLogger(__name__)

settings = get_settings()
async def consume_moderation_results():
    consumer = AIOKafkaConsumer(
        "activity.moderated",
        bootstrap_servers=settings.KAFKA_BOOTSTRAP_SERVERS,
        group_id="activity-service-moderation",
        value_deserializer=lambda v: json.loads(v.decode("utf-8")),
        auto_offset_reset="earliest",
    )

    await consumer.start()
    logger.info("Kafka consumer started: activity.moderated")

    try:
        async for msg in consumer:
            await _handle(msg.value)
    finally:
        await consumer.stop()


async def _handle(payload: dict):
    activity_id = payload.get("activity_id")
    status = payload.get("status")  # "published" | "rejected"

    if not activity_id or status not in ("published", "rejected"):
        logger.warning("Invalid moderation payload: %s", payload)
        return

    try:
        async with AsyncSessionLocal() as db:
            service = ActivityService(db)
            await service.update_status(activity_id, status)
            logger.info("Activity %s → %s", activity_id, status)
    except Exception as e:
        logger.error("Failed to update activity status: %s", e)