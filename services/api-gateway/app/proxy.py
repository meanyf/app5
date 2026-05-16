# proxy.py

import httpx
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request, Response, HTTPException

TIMEOUT = 30.0

# Заголовки которые НЕ пробрасываем (hop-by-hop)
SKIP_HEADERS = {"host", "transfer-encoding", "connection"}

_client: httpx.AsyncClient | None = None


def get_client() -> httpx.AsyncClient:
    return _client


@asynccontextmanager
async def lifespan(app: FastAPI):
    global _client
    _client = httpx.AsyncClient(timeout=TIMEOUT)
    yield
    await _client.aclose()


def _proxy_headers(request: Request) -> dict:
    headers = {
        k: v for k, v in request.headers.items()
        if k.lower() not in SKIP_HEADERS
    }
    # Перезаписываем X-User-Id из state (уже провалидированный)
    headers["x-user-id"] = getattr(request.state, "user_id", "")
    return headers


async def proxy_request(request: Request, url: str) -> Response:
    body = await request.body()
    headers = _proxy_headers(request)
    params = dict(request.query_params)

    try:
        response = await get_client().request(
            method=request.method,
            url=url,
            headers=headers,
            content=body,
            params=params,
        )
    except httpx.ConnectError:
        raise HTTPException(status_code=503, detail=f"Сервис недоступен: {url}")
    except httpx.TimeoutException:
        raise HTTPException(status_code=504, detail=f"Сервис не ответил вовремя: {url}")

    return Response(
        content=response.content,
        status_code=response.status_code,
        media_type=response.headers.get("content-type"),
    )