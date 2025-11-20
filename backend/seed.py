"""
Database seeding script for SmartBlink
Generates sample data for testing the optimization system
"""
import asyncio
import random
from datetime import datetime, timedelta
from typing import List, Tuple
import os
import sys

# Add parent directory to path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from prisma import Prisma


# Delhi NCR bounding box
DELHI_LAT_MIN = 28.4
DELHI_LAT_MAX = 28.9
DELHI_LON_MIN = 76.9
DELHI_LON_MAX = 77.4

# Hotspots with higher order density (lat, lon, weight)
HOTSPOTS = [
    (28.7041, 77.1025, 3.0),  # Connaught Place
    (28.6139, 77.2090, 2.5),  # Nehru Place
    (28.5355, 77.3910, 2.0),  # Noida
    (28.4595, 77.0266, 2.5),  # Gurgaon
    (28.6692, 77.4538, 1.8),  # Ghaziabad
    (28.7196, 77.0369, 2.0),  # Rohini
]


def generate_location(hotspot_probability: float = 0.7) -> Tuple[float, float]:
    """Generate a random location, biased towards hotspots"""
    if random.random() < hotspot_probability:
        # Pick a hotspot
        hotspot = random.choices(
            HOTSPOTS, 
            weights=[h[2] for h in HOTSPOTS]
        )[0]
        # Add some noise around the hotspot
        lat = hotspot[0] + random.gauss(0, 0.02)
        lon = hotspot[1] + random.gauss(0, 0.02)
    else:
        # Random location in Delhi
        lat = random.uniform(DELHI_LAT_MIN, DELHI_LAT_MAX)
        lon = random.uniform(DELHI_LON_MIN, DELHI_LON_MAX)
    
    return (lat, lon)


def generate_timestamp(days_back: int = 90) -> datetime:
    """Generate a random timestamp within the last N days"""
    now = datetime.now()
    random_days = random.uniform(0, days_back)
    random_hours = random.uniform(0, 24)
    
    # Bias towards peak hours (11am-2pm, 7pm-10pm)
    hour = random.choices(
        range(24),
        weights=[
            0.5, 0.5, 0.5, 0.5, 0.5, 0.8,  # 0-5am (low)
            1.0, 1.5, 2.0, 2.5, 3.0, 4.0,  # 6-11am (morning rise)
            4.5, 4.0, 3.5, 3.0, 2.5, 2.0,  # 12-5pm (afternoon)
            2.5, 4.0, 4.5, 4.0, 3.0, 1.5   # 6-11pm (evening peak)
        ]
    )[0]
    
    return now - timedelta(days=random_days, hours=hour, minutes=random.randint(0, 59))


async def seed_stores(db: Prisma, count: int = 5):
    """Create initial store locations"""
    print(f"🏪 Seeding {count} stores...")
    
    store_locations = [
        ("CP Store", 28.6315, 77.2167, "Connaught Place, New Delhi"),
        ("Noida Store", 28.5355, 77.3910, "Sector 18, Noida"),
        ("Gurgaon Store", 28.4595, 77.0266, "Cyber City, Gurgaon"),
        ("Rohini Store", 28.7196, 77.0369, "Rohini, Delhi"),
        ("East Delhi Store", 28.6692, 77.4538, "Ghaziabad"),
    ]
    
    for i in range(min(count, len(store_locations))):
        name, lat, lon, address = store_locations[i]
        
        # Use raw SQL for PostGIS geometry
        await db.execute_raw(
            f"""
            INSERT INTO stores (name, location, address, city, is_active, capacity, monthly_rent, setup_cost, opened_at, created_at, updated_at)
            VALUES (
                '{name}',
                ST_SetSRID(ST_MakePoint({lon}, {lat}), 4326),
                '{address}',
                'Delhi NCR',
                true,
                {random.randint(200, 500)},
                {random.randint(50000, 150000)},
                {random.randint(500000, 2000000)},
                NOW() - INTERVAL '{random.randint(30, 365)} days',
                NOW(),
                NOW()
            )
            """
        )
    
    print(f"✅ Created {count} stores")


async def seed_orders(db: Prisma, count: int = 10000):
    """Create historical order data"""
    print(f"📦 Seeding {count} orders...")
    
    batch_size = 1000
    for batch_start in range(0, count, batch_size):
        batch_count = min(batch_size, count - batch_start)
        values = []
        
        for _ in range(batch_count):
            lat, lon = generate_location()
            timestamp = generate_timestamp()
            items_count = random.randint(1, 15)
            order_value = round(random.uniform(200, 3000), 2)
            delivery_time = random.randint(5, 45)
            
            values.append(
                f"(ST_SetSRID(ST_MakePoint({lon}, {lat}), 4326), "
                f"'{timestamp.isoformat()}', {items_count}, {order_value}, "
                f"'CUST{random.randint(1000, 9999)}', "
                f"'{(timestamp + timedelta(minutes=delivery_time)).isoformat()}', "
                f"{delivery_time}, NULL, 'completed', NOW())"
            )
        
        # Batch insert
        await db.execute_raw(
            f"""
            INSERT INTO orders (location, timestamp, items_count, order_value, customer_id, delivered_at, delivery_time_min, store_id, status, created_at)
            VALUES {', '.join(values)}
            """
        )
        
        print(f"  ✓ Inserted {batch_start + batch_count}/{count} orders")
    
    print(f"✅ Created {count} orders")


async def seed_demand_cells(db: Prisma):
    """Generate demand cells from order data"""
    print("🗺️  Generating demand cells...")
    
    # Create a grid of hexagons covering Delhi NCR
    # Using 0.05 degree cells (~5km)
    cell_size = 0.05
    
    lat_steps = int((DELHI_LAT_MAX - DELHI_LAT_MIN) / cell_size) + 1
    lon_steps = int((DELHI_LON_MAX - DELHI_LON_MIN) / cell_size) + 1
    
    total_cells = 0
    for i in range(lat_steps):
        for j in range(lon_steps):
            lat_min = DELHI_LAT_MIN + i * cell_size
            lat_max = lat_min + cell_size
            lon_min = DELHI_LON_MIN + j * cell_size
            lon_max = lon_min + cell_size
            
            # Create polygon for this cell
            polygon_wkt = f"POLYGON(({lon_min} {lat_min}, {lon_max} {lat_min}, {lon_max} {lat_max}, {lon_min} {lat_max}, {lon_min} {lat_min}))"
            
            # Count orders in this cell
            result = await db.query_raw(
                f"""
                SELECT 
                    COUNT(*) as orders_count,
                    COALESCE(SUM(order_value), 0) as total_value,
                    COALESCE(AVG(order_value), 0) as avg_value,
                    EXTRACT(HOUR FROM timestamp)::INT as peak_hour
                FROM orders
                WHERE ST_Within(location, ST_SetSRID(ST_GeomFromText('{polygon_wkt}'), 4326))
                GROUP BY EXTRACT(HOUR FROM timestamp)
                ORDER BY COUNT(*) DESC
                LIMIT 1
                """
            )
            
            if result and result[0]['orders_count'] > 0:
                orders_count = result[0]['orders_count']
                total_value = float(result[0]['total_value'])
                avg_value = float(result[0]['avg_value'])
                peak_hour = result[0]['peak_hour']
                demand_score = min(orders_count / 10.0, 10.0)  # Normalize to 0-10
                
                await db.execute_raw(
                    f"""
                    INSERT INTO demand_cells (
                        cell_geometry, demand_score, orders_count, 
                        total_order_value, avg_order_value, peak_hour,
                        period_start, period_end, created_at
                    )
                    VALUES (
                        ST_SetSRID(ST_GeomFromText('{polygon_wkt}'), 4326),
                        {demand_score}, {orders_count}, {total_value}, {avg_value}, {peak_hour},
                        NOW() - INTERVAL '90 days', NOW(), NOW()
                    )
                    """
                )
                total_cells += 1
    
    print(f"✅ Created {total_cells} demand cells with order data")


async def main():
    """Main seeding function"""
    print("🌱 Starting database seeding...\n")
    
    db = Prisma()
    await db.connect()
    
    try:
        # Check if data already exists
        store_count = await db.query_raw("SELECT COUNT(*) as count FROM stores")
        if store_count and store_count[0]['count'] > 0:
            print("⚠️  Database already has data. Clear it first? (y/n)")
            response = input().lower()
            if response != 'y':
                print("❌ Seeding cancelled")
                return
            
            # Clear existing data
            print("🧹 Clearing existing data...")
            await db.execute_raw("TRUNCATE stores, orders, demand_cells, candidates, optimization_jobs, isochrones CASCADE")
        
        # Seed data
        await seed_stores(db, count=5)
        await seed_orders(db, count=10000)
        await seed_demand_cells(db)
        
        # Print summary
        print("\n📊 Database Summary:")
        stores = await db.query_raw("SELECT COUNT(*) as count FROM stores")
        orders = await db.query_raw("SELECT COUNT(*) as count FROM orders")
        cells = await db.query_raw("SELECT COUNT(*) as count FROM demand_cells")
        
        print(f"  Stores: {stores[0]['count']}")
        print(f"  Orders: {orders[0]['count']}")
        print(f"  Demand Cells: {cells[0]['count']}")
        
        print("\n✅ Seeding completed successfully!")
        
    except Exception as e:
        print(f"\n❌ Error during seeding: {e}")
        raise
    finally:
        await db.disconnect()


if __name__ == "__main__":
    asyncio.run(main())
