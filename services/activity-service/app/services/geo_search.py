# geo_search.py

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.activity import Activity


async def find_activities_within_radius(
    db: AsyncSession,
    latitude: float,
    longitude: float,
    radius_meters: float = 5000,
) -> list[Activity]:
    query = text("""
        SELECT * FROM activities
        WHERE ST_DWithin(
            location::geography,
            ST_MakePoint(:longitude, :latitude)::geography,
            :radius
        )
        AND expires_at > NOW()
        ORDER BY starts_at ASC
    """)
    result = await db.execute(query, {
        "latitude": latitude,
        "longitude": longitude,
        "radius": radius_meters,
    })
    return result.fetchall()