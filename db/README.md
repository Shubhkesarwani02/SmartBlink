# Prisma Database Setup

This directory contains the Prisma schema and migrations for SmartBlink.

## Prerequisites

1. Install Prisma CLI:
```bash
pip install prisma
```

2. Generate Prisma client:
```bash
cd backend
prisma generate
```

## Running Migrations

1. Create a new migration:
```bash
prisma migrate dev --name init
```

2. Apply migrations in production:
```bash
prisma migrate deploy
```

## PostGIS Support

The schema uses PostGIS extensions for geospatial data. Key features:

- `geometry(Point, 4326)` - Stores lat/lon coordinates in WGS84
- `geometry(Polygon, 4326)` - Stores grid cells and coverage areas
- GIST indexes for fast spatial queries

## Direct SQL Queries

For complex spatial operations, use raw SQL:

```python
from prisma import Prisma

prisma = Prisma()
await prisma.connect()

result = await prisma.query_raw('''
    SELECT id, name, ST_AsText(location) as location
    FROM stores
    WHERE ST_DWithin(
        location::geography,
        ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography,
        5000  -- 5km radius
    )
''', longitude, latitude)
```
