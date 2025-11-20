"""
Quick test script to verify database connection and PostGIS setup
"""
import asyncio
import sys
import os

# Add parent directory to path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from prisma import Prisma


async def test_connection():
    """Test basic database connectivity"""
    print("🔌 Testing database connection...")
    
    db = Prisma()
    try:
        await db.connect()
        print("✅ Database connected successfully")
        return db
    except Exception as e:
        print(f"❌ Connection failed: {e}")
        sys.exit(1)


async def test_postgis(db: Prisma):
    """Test PostGIS extension"""
    print("\n🗺️  Testing PostGIS...")
    
    try:
        result = await db.query_raw("SELECT PostGIS_version();")
        version = result[0]['postgis_version']
        print(f"✅ PostGIS version: {version}")
    except Exception as e:
        print(f"❌ PostGIS test failed: {e}")
        return False
    
    return True


async def test_tables(db: Prisma):
    """Test that all required tables exist"""
    print("\n📋 Checking tables...")
    
    tables = ['stores', 'orders', 'demand_cells', 'candidates', 'optimization_jobs', 'isochrones']
    
    for table in tables:
        try:
            result = await db.query_raw(
                f"SELECT COUNT(*) as count FROM information_schema.tables WHERE table_name='{table}';"
            )
            if result[0]['count'] == 1:
                # Get row count
                count_result = await db.query_raw(f"SELECT COUNT(*) as count FROM {table};")
                row_count = count_result[0]['count']
                print(f"  ✅ {table} (rows: {row_count})")
            else:
                print(f"  ❌ {table} (not found)")
        except Exception as e:
            print(f"  ❌ {table} (error: {e})")


async def test_spatial_query(db: Prisma):
    """Test a simple spatial query"""
    print("\n🌍 Testing spatial queries...")
    
    try:
        # Create a test point
        result = await db.query_raw("""
            SELECT 
                ST_AsText(ST_SetSRID(ST_MakePoint(77.2090, 28.6139), 4326)) as point,
                ST_Distance(
                    ST_SetSRID(ST_MakePoint(77.2090, 28.6139), 4326)::geography,
                    ST_SetSRID(ST_MakePoint(77.1025, 28.7041), 4326)::geography
                ) as distance_meters
        """)
        
        point = result[0]['point']
        distance = round(result[0]['distance_meters'], 2)
        print(f"✅ Created point: {point}")
        print(f"✅ Distance calculation: {distance} meters")
    except Exception as e:
        print(f"❌ Spatial query failed: {e}")
        return False
    
    return True


async def test_helper_functions(db: Prisma):
    """Test custom PostGIS helper functions"""
    print("\n🔧 Testing helper functions...")
    
    functions = [
        ('calculate_distance_meters', "SELECT calculate_distance_meters(28.6139, 77.2090, 28.7041, 77.1025);"),
        ('make_point_wgs84', "SELECT ST_AsText(make_point_wgs84(28.6139, 77.2090));"),
    ]
    
    for func_name, query in functions:
        try:
            result = await db.query_raw(query)
            print(f"  ✅ {func_name} works")
        except Exception as e:
            print(f"  ⚠️  {func_name} not found (optional)")


async def main():
    """Run all tests"""
    print("=" * 60)
    print("🧪 SmartBlink Database Test Suite")
    print("=" * 60)
    
    db = await test_connection()
    
    try:
        postgis_ok = await test_postgis(db)
        await test_tables(db)
        
        if postgis_ok:
            await test_spatial_query(db)
            await test_helper_functions(db)
        
        print("\n" + "=" * 60)
        print("✅ All tests completed!")
        print("=" * 60)
        
        # Check if data exists
        stores = await db.query_raw("SELECT COUNT(*) as count FROM stores;")
        if stores[0]['count'] == 0:
            print("\n💡 Tip: Run 'python seed.py' to populate with sample data")
        
    except Exception as e:
        print(f"\n❌ Test suite failed: {e}")
        sys.exit(1)
    finally:
        await db.disconnect()


if __name__ == "__main__":
    asyncio.run(main())
