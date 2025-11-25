#!/usr/bin/env python3
"""
Comprehensive validation script for SmartBlink Phase 0-2 setup
Checks all components: Docker, Database, Schema, Data, and Processing Pipeline
"""

import sys
import subprocess
import psycopg2
from datetime import datetime
import requests

# Color codes for terminal output
GREEN = '\033[92m'
YELLOW = '\033[93m'
RED = '\033[91m'
BLUE = '\033[94m'
RESET = '\033[0m'
BOLD = '\033[1m'

def print_section(title):
    """Print a section header"""
    print(f"\n{BLUE}{BOLD}{'='*80}{RESET}")
    print(f"{BLUE}{BOLD}{title.center(80)}{RESET}")
    print(f"{BLUE}{BOLD}{'='*80}{RESET}\n")

def print_check(item, status, details=""):
    """Print a check result"""
    symbol = f"{GREEN}✅{RESET}" if status else f"{RED}❌{RESET}"
    print(f"{symbol} {item}")
    if details:
        print(f"   {details}")

def run_command(cmd, capture=True):
    """Run a shell command and return output"""
    try:
        result = subprocess.run(
            cmd, 
            shell=True, 
            capture_output=capture, 
            text=True, 
            timeout=10
        )
        return result.returncode == 0, result.stdout.strip() if capture else ""
    except Exception as e:
        return False, str(e)

def check_docker_services():
    """Check if Docker services are running"""
    print_section("PHASE 0: Docker Infrastructure")
    
    # Check Docker is running
    success, _ = run_command("docker info")
    print_check("Docker daemon", success)
    
    if not success:
        return False
    
    # Check docker-compose services
    services = ['smartblink-db', 'smartblink-backend', 'smartblink-frontend', 'smartblink-redis']
    all_running = True
    
    for service in services:
        success, output = run_command(f"docker ps --filter name={service} --format '{{{{.Status}}}}'")
        is_up = success and 'Up' in output
        print_check(f"Service: {service}", is_up, output if is_up else "Not running")
        all_running = all_running and is_up
    
    # Check service endpoints
    endpoints = [
        ("FastAPI Backend", "http://localhost:8000/docs"),
        ("React Frontend", "http://localhost:3000"),
    ]
    
    for name, url in endpoints:
        try:
            response = requests.get(url, timeout=5)
            is_ok = response.status_code == 200
            print_check(f"{name} accessible", is_ok, url)
        except Exception as e:
            print_check(f"{name} accessible", False, f"Error: {str(e)[:50]}")
            all_running = False
    
    return all_running

def check_database():
    """Check database schema and PostGIS"""
    print_section("PHASE 1: Database & Schema")
    
    try:
        conn = psycopg2.connect(
            host="localhost",
            port=5432,
            database="smartblink",
            user="smartblink",
            password="smartblink123"
        )
        cursor = conn.cursor()
        print_check("Database connection", True, "postgresql://localhost:5432/smartblink")
        
        # Check PostGIS extension
        cursor.execute("SELECT extname, extversion FROM pg_extension WHERE extname LIKE 'postgis%';")
        extensions = cursor.fetchall()
        has_postgis = len(extensions) > 0
        ext_details = ", ".join([f"{e[0]} v{e[1]}" for e in extensions])
        print_check("PostGIS extensions", has_postgis, ext_details)
        
        # Check required tables
        required_tables = ['stores', 'orders', 'demand_cells', 'candidates', 'optimization_jobs', 'isochrones']
        cursor.execute("""
            SELECT tablename FROM pg_tables 
            WHERE schemaname = 'public' AND tablename IN %s
        """, (tuple(required_tables),))
        existing_tables = [row[0] for row in cursor.fetchall()]
        
        for table in required_tables:
            exists = table in existing_tables
            print_check(f"Table: {table}", exists)
        
        all_tables_exist = len(existing_tables) == len(required_tables)
        
        # Check spatial indexes
        cursor.execute("""
            SELECT tablename, indexname 
            FROM pg_indexes 
            WHERE indexdef LIKE '%GIST%' 
            AND tablename IN ('stores', 'orders', 'demand_cells')
            ORDER BY tablename
        """)
        spatial_indexes = cursor.fetchall()
        print_check("Spatial GIST indexes", len(spatial_indexes) > 0, 
                   f"{len(spatial_indexes)} spatial indexes found")
        
        cursor.close()
        conn.close()
        return all_tables_exist and has_postgis
        
    except Exception as e:
        print_check("Database connection", False, str(e))
        return False

def check_seed_data():
    """Check if mock data is properly seeded"""
    print_section("PHASE 1: Seed Data Validation")
    
    try:
        conn = psycopg2.connect(
            host="localhost",
            port=5432,
            database="smartblink",
            user="smartblink",
            password="smartblink123"
        )
        cursor = conn.cursor()
        
        # Check stores
        cursor.execute("SELECT COUNT(*) FROM stores")
        store_count = cursor.fetchone()[0]
        print_check("Stores seeded", store_count >= 5, f"{store_count} stores")
        
        cursor.execute("SELECT name, ST_Y(location::geometry), ST_X(location::geometry) FROM stores ORDER BY id")
        stores = cursor.fetchall()
        for name, lat, lon in stores:
            print(f"   📍 {name}: ({lat:.4f}, {lon:.4f})")
        
        # Check orders
        cursor.execute("SELECT COUNT(*) FROM orders")
        order_count = cursor.fetchone()[0]
        has_orders = order_count >= 1000
        print_check("Orders seeded", has_orders, f"{order_count:,} orders")
        
        cursor.execute("""
            SELECT 
                MIN(timestamp)::date as earliest,
                MAX(timestamp)::date as latest,
                SUM(order_value) as total_value
            FROM orders
        """)
        earliest, latest, total_value = cursor.fetchone()
        print(f"   📅 Date range: {earliest} to {latest}")
        print(f"   💰 Total value: ₹{total_value:,.2f}")
        
        # Test geometric queries
        cursor.execute("""
            SELECT ST_Distance(
                (SELECT location::geography FROM stores LIMIT 1),
                (SELECT location::geography FROM orders LIMIT 1)
            )
        """)
        distance = cursor.fetchone()[0]
        geometric_ok = distance is not None
        print_check("PostGIS geometric functions", geometric_ok, 
                   f"ST_Distance working (sample: {distance:.0f}m)")
        
        cursor.close()
        conn.close()
        return has_orders and store_count >= 5 and geometric_ok
        
    except Exception as e:
        print_check("Seed data validation", False, str(e))
        return False

def check_phase2_processing():
    """Check if Phase 2 data processing has been completed"""
    print_section("PHASE 2: Data Processing Pipeline")
    
    try:
        conn = psycopg2.connect(
            host="localhost",
            port=5432,
            database="smartblink",
            user="smartblink",
            password="smartblink123"
        )
        cursor = conn.cursor()
        
        # Check demand_cells
        cursor.execute("SELECT COUNT(*) FROM demand_cells")
        cell_count = cursor.fetchone()[0]
        has_cells = cell_count > 0
        print_check("Demand cells generated", has_cells, f"{cell_count} hexagons")
        
        if has_cells:
            # Check H3 indices
            cursor.execute("SELECT COUNT(*) FROM demand_cells WHERE h3_index IS NOT NULL")
            h3_count = cursor.fetchone()[0]
            has_h3 = h3_count > 0
            print_check("H3 indexing applied", has_h3, 
                       f"{h3_count}/{cell_count} cells have H3 indices")
            
            # Check metrics
            cursor.execute("""
                SELECT 
                    COUNT(*) as total,
                    AVG(orders_count) as avg_orders,
                    MAX(demand_score) as max_score,
                    MIN(demand_score) as min_score
                FROM demand_cells
            """)
            total, avg_orders, max_score, min_score = cursor.fetchone()
            print_check("Demand metrics calculated", True,
                       f"Avg orders/cell: {avg_orders:.1f}, Score range: {min_score:.1f}-{max_score:.1f}")
            
            # Check distance calculations
            cursor.execute("""
                SELECT COUNT(*) 
                FROM demand_cells 
                WHERE distance_to_nearest_store IS NOT NULL
            """)
            dist_count = cursor.fetchone()[0]
            has_distances = dist_count > 0
            
            if has_distances:
                cursor.execute("""
                    SELECT 
                        MIN(distance_to_nearest_store),
                        MAX(distance_to_nearest_store),
                        AVG(distance_to_nearest_store)
                    FROM demand_cells
                    WHERE distance_to_nearest_store IS NOT NULL
                """)
                min_dist, max_dist, avg_dist = cursor.fetchone()
                print_check("Distance calculations", has_distances,
                           f"{dist_count} cells, Range: {min_dist:.0f}m-{max_dist:.0f}m, Avg: {avg_dist:.0f}m")
            else:
                print_check("Distance calculations", False, "No distances computed")
            
            # Top demand areas
            cursor.execute("""
                SELECT h3_index, orders_count, demand_score
                FROM demand_cells
                WHERE h3_index IS NOT NULL
                ORDER BY demand_score DESC
                LIMIT 3
            """)
            top_cells = cursor.fetchall()
            if top_cells:
                print(f"\n   🔥 Top 3 demand areas:")
                for h3, orders, score in top_cells:
                    print(f"      H3: {h3[:12]}... | {orders} orders | Score: {score:.1f}")
            
            processing_complete = has_h3 and has_distances
        else:
            processing_complete = False
            print(f"   {YELLOW}⚠️  Run the Phase 2 notebook to process data{RESET}")
        
        cursor.close()
        conn.close()
        return processing_complete
        
    except Exception as e:
        print_check("Phase 2 processing", False, str(e))
        return False

def check_visualizations():
    """Check if visualizations have been generated"""
    print_section("PHASE 2: Visualizations")
    
    import os
    outputs_dir = "/Users/shubh/Desktop/SmartBlink/outputs"
    
    if not os.path.exists(outputs_dir):
        print_check("Outputs directory", False, "Directory not found")
        print(f"   {YELLOW}⚠️  Run Phase 2 notebook to generate visualizations{RESET}")
        return False
    
    print_check("Outputs directory", True, outputs_dir)
    
    expected_files = [
        "phase2_demand_analysis.png",
        "phase2_statistical_distributions.png",
        "phase2_interactive_map.html"
    ]
    
    all_exist = True
    for filename in expected_files:
        filepath = os.path.join(outputs_dir, filename)
        exists = os.path.exists(filepath)
        print_check(f"Visualization: {filename}", exists)
        all_exist = all_exist and exists
    
    return all_exist

def main():
    """Run all validation checks"""
    print(f"\n{BOLD}🔍 SmartBlink Setup Validation{RESET}")
    print(f"{BOLD}{'─'*80}{RESET}")
    print(f"Checking Phases 0, 1, and 2...")
    print(f"Timestamp: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    results = []
    
    # Run all checks
    results.append(("Phase 0: Docker Infrastructure", check_docker_services()))
    results.append(("Phase 1: Database & Schema", check_database()))
    results.append(("Phase 1: Seed Data", check_seed_data()))
    results.append(("Phase 2: Data Processing", check_phase2_processing()))
    results.append(("Phase 2: Visualizations", check_visualizations()))
    
    # Summary
    print_section("VALIDATION SUMMARY")
    
    total = len(results)
    passed = sum(1 for _, status in results if status)
    
    for name, status in results:
        symbol = f"{GREEN}✅ PASS{RESET}" if status else f"{RED}❌ FAIL{RESET}"
        print(f"{symbol} {name}")
    
    print(f"\n{BOLD}Overall Status: {passed}/{total} checks passed{RESET}")
    
    if passed == total:
        print(f"\n{GREEN}{BOLD}🎉 All systems operational! Setup is complete.{RESET}")
        print(f"\n{BOLD}Next Steps:{RESET}")
        print(f"   1. Review visualizations in outputs/ directory")
        print(f"   2. Open outputs/phase2_interactive_map.html in browser")
        print(f"   3. Proceed to Phase 3: Candidate Site Generation")
        return 0
    else:
        print(f"\n{YELLOW}{BOLD}⚠️  Some checks failed. Review the details above.{RESET}")
        if not results[3][1]:  # Phase 2 processing failed
            print(f"\n{BOLD}To complete Phase 2 processing:{RESET}")
            print(f"   Run the Jupyter notebook: ml/phase2_data_processing.ipynb")
            print(f"   Or use: make process-data")
        return 1

if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print(f"\n{YELLOW}Validation interrupted by user{RESET}")
        sys.exit(1)
    except Exception as e:
        print(f"\n{RED}Unexpected error: {e}{RESET}")
        sys.exit(1)
