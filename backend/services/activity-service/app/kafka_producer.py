import json

from aiokafka import AIOKafkaProducer

from app.config import settings

_producer: AIOKafkaProducer | None = None


async def init_producer():
    global _producer
    _producer = AIOKafkaProducer(bootstrap_servers=settings.kafka_bootstrap_servers)
    await _producer.start()


async def close_producer():
    if _producer:
        await _producer.stop()


async def publish(topic: str, data: dict):
    if _producer:
        await _producer.send_and_wait(topic, json.dumps(data).encode())
