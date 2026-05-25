# producer.py

import json
from aiokafka import AIOKafkaProducer
from app.config import get_settings

settings = get_settings()
import json
import logging
from aiokafka import AIOKafkaProducer
from app.config import get_settings

settings = get_settings()
logger = logging.getLogger(__name__)

async def send_meeting_request_event(
    activity_id: str,
    creator_id: str,
    requester_id: str,
) -> None:
    logger.info(f"Sending meeting_request_created event: activity={activity_id} creator={creator_id}")
    producer = AIOKafkaProducer(
        bootstrap_servers=settings.KAFKA_BOOTSTRAP_SERVERS
    )
    await producer.start()
    try:
        payload = json.dumps({
            "activity_id": activity_id,
            "creator_id": creator_id,
            "requester_id": requester_id,
        }).encode()
        await producer.send_and_wait("meeting_request_created", payload)
        logger.info("Event sent successfully")
    except Exception as e:
        logger.error(f"Failed to send event: {e}")
    finally:
        await producer.stop()