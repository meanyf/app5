# ffmpeg.py

import asyncio
import os


async def transcode_video(input_path: str, output_path: str) -> None:
    """Перекодирует видео в H.264/AAC MP4, максимум 1080p."""
    command = [
        "ffmpeg",
        "-i", input_path,
        "-vf", "scale=-2:'min(1080,ih)'",
        "-c:v", "libx264",
        "-crf", "28",
        "-preset", "fast",
        "-c:a", "aac",
        "-b:a", "128k",
        "-movflags", "+faststart",
        "-y",
        output_path,
    ]
    process = await asyncio.create_subprocess_exec(
        *command,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
    )
    _, stderr = await process.communicate()
    if process.returncode != 0:
        raise RuntimeError(f"FFmpeg error: {stderr.decode()}")


async def extract_thumbnail(input_path: str, thumbnail_path: str) -> None:
    """Извлекает кадр из середины видео как превью."""
    command = [
        "ffprobe",
        "-v", "error",
        "-show_entries", "format=duration",
        "-of", "default=noprint_wrappers=1:nokey=1",
        input_path,
    ]
    process = await asyncio.create_subprocess_exec(
        *command,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
    )
    stdout, _ = await process.communicate()
    duration = float(stdout.decode().strip() or "0")
    midpoint = duration / 2

    command = [
        "ffmpeg",
        "-ss", str(midpoint),
        "-i", input_path,
        "-frames:v", "1",
        "-q:v", "2",
        "-y",
        thumbnail_path,
    ]
    process = await asyncio.create_subprocess_exec(
        *command,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
    )
    await process.communicate()