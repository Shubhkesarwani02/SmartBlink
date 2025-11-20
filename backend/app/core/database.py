"""
Database connection and utility functions
"""
from prisma import Prisma
from typing import Optional
import logging

logger = logging.getLogger(__name__)

# Global Prisma client instance
_prisma_client: Optional[Prisma] = None


async def get_db() -> Prisma:
    """Get or create Prisma database connection"""
    global _prisma_client
    
    if _prisma_client is None:
        _prisma_client = Prisma()
        await _prisma_client.connect()
        logger.info("📊 Database connected")
    
    return _prisma_client


async def close_db():
    """Close database connection"""
    global _prisma_client
    
    if _prisma_client is not None:
        await _prisma_client.disconnect()
        _prisma_client = None
        logger.info("📊 Database disconnected")


async def execute_spatial_query(query: str, *args):
    """Execute raw SQL query with PostGIS functions"""
    db = await get_db()
    return await db.query_raw(query, *args)


async def create_point_wkt(lat: float, lon: float) -> str:
    """Create WKT point string for PostGIS"""
    return f"POINT({lon} {lat})"


async def insert_with_geometry(
    table: str,
    data: dict,
    geometry_field: str = "location",
    lat_key: str = "latitude",
    lon_key: str = "longitude"
):
    """Helper to insert data with PostGIS geometry"""
    db = await get_db()
    
    # Extract lat/lon
    lat = data.pop(lat_key)
    lon = data.pop(lon_key)
    
    # Build column and value strings
    columns = list(data.keys()) + [geometry_field]
    placeholders = []
    values = []
    
    for i, (key, value) in enumerate(data.items(), 1):
        placeholders.append(f"${i}")
        values.append(value)
    
    # Add geometry as WKT
    placeholders.append(f"ST_SetSRID(ST_MakePoint(${len(values) + 1}, ${len(values) + 2}), 4326)")
    values.extend([lon, lat])
    
    query = f"""
        INSERT INTO {table} ({', '.join(columns)})
        VALUES ({', '.join(placeholders)})
        RETURNING *
    """
    
    return await db.query_raw(query, *values)
