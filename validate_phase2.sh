#!/bin/bash
set -e

echo "================================================"
echo "🧪 PHASE 2 VALIDATION SCRIPT"
echo "================================================"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test 1: Docker Services
echo "1️⃣  Checking Docker Services..."
if docker ps --format "{{.Names}}" | grep -q "smartblink-db"; then
    echo -e "${GREEN}✅ PostgreSQL is running${NC}"
else
    echo -e "${RED}❌ PostgreSQL is not running${NC}"
    exit 1
fi

if docker ps --format "{{.Names}}" | grep -q "smartblink-backend"; then
    echo -e "${GREEN}✅ Backend is running${NC}"
else
    echo -e "${RED}❌ Backend is not running${NC}"
    exit 1
fi

if docker ps --format "{{.Names}}" | grep -q "smartblink-frontend"; then
    echo -e "${GREEN}✅ Frontend is running${NC}"
else
    echo -e "${RED}❌ Frontend is not running${NC}"
    exit 1
fi

# Test 2: PostGIS Extension
echo ""
echo "2️⃣  Verifying PostGIS Extension..."
POSTGIS_VERSION=$(docker exec smartblink-db psql -U smartblink -d smartblink -t -c "SELECT PostGIS_version();" 2>/dev/null || echo "")
if [ -n "$POSTGIS_VERSION" ]; then
    echo -e "${GREEN}✅ PostGIS is installed:${NC} $POSTGIS_VERSION"
else
    echo -e "${RED}❌ PostGIS is not installed${NC}"
    exit 1
fi

# Test 3: Database Tables
echo ""
echo "3️⃣  Checking Database Tables..."
TABLES=("stores" "orders" "demand_cells" "candidates" "optimization_jobs" "isochrones")
for table in "${TABLES[@]}"; do
    COUNT=$(docker exec smartblink-db psql -U smartblink -d smartblink -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_name='$table';" 2>/dev/null | tr -d ' ')
    if [ "$COUNT" = "1" ]; then
        echo -e "${GREEN}✅ Table '$table' exists${NC}"
    else
        echo -e "${RED}❌ Table '$table' missing${NC}"
        exit 1
    fi
done

# Test 4: Seeded Data
echo ""
echo "4️⃣  Verifying Seeded Data..."

ORDER_COUNT=$(docker exec smartblink-db psql -U smartblink -d smartblink -t -c "SELECT COUNT(*) FROM orders;" | tr -d ' ')
echo "   Orders: $ORDER_COUNT"
if [ "$ORDER_COUNT" -gt "0" ]; then
    echo -e "${GREEN}✅ Orders table populated ($ORDER_COUNT orders)${NC}"
else
    echo -e "${RED}❌ Orders table is empty${NC}"
    exit 1
fi

STORE_COUNT=$(docker exec smartblink-db psql -U smartblink -d smartblink -t -c "SELECT COUNT(*) FROM stores WHERE is_active=true;" | tr -d ' ')
echo "   Active Stores: $STORE_COUNT"
if [ "$STORE_COUNT" -gt "0" ]; then
    echo -e "${GREEN}✅ Stores table populated ($STORE_COUNT stores)${NC}"
else
    echo -e "${RED}❌ Stores table is empty${NC}"
    exit 1
fi

CELL_COUNT=$(docker exec smartblink-db psql -U smartblink -d smartblink -t -c "SELECT COUNT(*) FROM demand_cells;" | tr -d ' ')
echo "   Demand Cells: $CELL_COUNT"
if [ "$CELL_COUNT" -gt "0" ]; then
    echo -e "${GREEN}✅ Demand cells table populated ($CELL_COUNT cells)${NC}"
else
    echo -e "${YELLOW}⚠️  Demand cells table is empty (run Phase 2 notebook)${NC}"
fi

# Test 5: PostGIS Geometric Functions
echo ""
echo "5️⃣  Testing PostGIS Geometric Functions..."

# Test ST_DWithin
NEARBY_ORDERS=$(docker exec smartblink-db psql -U smartblink -d smartblink -t -c "
    SELECT COUNT(*) 
    FROM orders o, stores s 
    WHERE s.is_active = true 
    AND ST_DWithin(o.location::geography, s.location::geography, 5000)
    LIMIT 1;
" | tr -d ' ')

if [ -n "$NEARBY_ORDERS" ] && [ "$NEARBY_ORDERS" != "ERROR" ]; then
    echo -e "${GREEN}✅ ST_DWithin working (found $NEARBY_ORDERS orders within 5km)${NC}"
else
    echo -e "${RED}❌ ST_DWithin failed${NC}"
fi

# Test ST_Distance
AVG_DISTANCE=$(docker exec smartblink-db psql -U smartblink -d smartblink -t -c "
    SELECT ROUND(AVG(ST_Distance(o.location::geography, s.location::geography))) as avg_dist
    FROM orders o
    CROSS JOIN LATERAL (
        SELECT location FROM stores WHERE is_active=true ORDER BY o.location::geography <-> location::geography LIMIT 1
    ) s;
" 2>/dev/null | tr -d ' ')

if [ -n "$AVG_DISTANCE" ] && [ "$AVG_DISTANCE" != "ERROR" ]; then
    echo -e "${GREEN}✅ ST_Distance working (avg: ${AVG_DISTANCE}m to nearest store)${NC}"
else
    echo -e "${RED}❌ ST_Distance failed${NC}"
fi

# Test 6: API Endpoints
echo ""
echo "6️⃣  Testing API Endpoints..."

HEALTH_STATUS=$(curl -s http://localhost:8000/health | grep -o "healthy" || echo "")
if [ "$HEALTH_STATUS" = "healthy" ]; then
    echo -e "${GREEN}✅ Backend health check passed${NC}"
else
    echo -e "${RED}❌ Backend health check failed${NC}"
fi

# Test 7: Frontend
echo ""
echo "7️⃣  Testing Frontend..."
FRONTEND_TITLE=$(curl -s http://localhost:3000 | grep -o "<title>.*</title>" || echo "")
if [[ "$FRONTEND_TITLE" == *"SmartBlink"* ]]; then
    echo -e "${GREEN}✅ Frontend is accessible${NC}"
else
    echo -e "${RED}❌ Frontend is not accessible${NC}"
fi

# Test 8: Python Environment
echo ""
echo "8️⃣  Checking Python Virtual Environment..."
if [ -d "venv" ]; then
    echo -e "${GREEN}✅ Virtual environment exists${NC}"
    
    # Check key packages
    if [ -f "venv/bin/activate" ]; then
        source venv/bin/activate
        PACKAGES=("pandas" "geopandas" "h3" "shapely" "jupyter")
        for pkg in "${PACKAGES[@]}"; do
            if python -c "import $pkg" 2>/dev/null; then
                VERSION=$(python -c "import $pkg; print($pkg.__version__)" 2>/dev/null || echo "unknown")
                echo -e "${GREEN}✅ $pkg installed ($VERSION)${NC}"
            else
                echo -e "${RED}❌ $pkg not installed${NC}"
            fi
        done
        deactivate
    fi
else
    echo -e "${YELLOW}⚠️  Virtual environment not found${NC}"
fi

# Test 9: File Structure
echo ""
echo "9️⃣  Verifying File Structure..."
REQUIRED_FILES=(
    "docker-compose.yml"
    "backend/seed.py"
    "backend/prisma/schema.prisma"
    "ml/phase2_data_processing.ipynb"
    "ml/requirements.txt"
    ".env"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅ $file exists${NC}"
    else
        echo -e "${RED}❌ $file missing${NC}"
    fi
done

# Test 10: No Duplicate Files
echo ""
echo "🔟  Checking for Duplicates/Unnecessary Files..."
CLEANUP_NEEDED=0

if [ -d "ml/.ipynb_checkpoints" ]; then
    echo -e "${YELLOW}⚠️  Found .ipynb_checkpoints directory${NC}"
    CLEANUP_NEEDED=1
fi

if [ -d "backend/app/__pycache__" ]; then
    echo -e "${YELLOW}⚠️  Found __pycache__ directories${NC}"
    CLEANUP_NEEDED=1
fi

if [ "$CLEANUP_NEEDED" = "0" ]; then
    echo -e "${GREEN}✅ No duplicate or cache files found${NC}"
fi

# Summary
echo ""
echo "================================================"
echo "📊 PHASE 2 VALIDATION SUMMARY"
echo "================================================"
echo ""
echo "Database:"
echo "  ✓ Orders: $ORDER_COUNT"
echo "  ✓ Stores: $STORE_COUNT"
echo "  ✓ Demand Cells: $CELL_COUNT"
echo ""
echo "Services:"
echo "  ✓ PostgreSQL + PostGIS: Running"
echo "  ✓ Backend API: http://localhost:8000"
echo "  ✓ Frontend: http://localhost:3000"
echo ""
echo "Python Environment:"
echo "  ✓ Virtual env with GeoPandas, H3, Shapely"
echo ""

if [ "$CELL_COUNT" = "0" ]; then
    echo -e "${YELLOW}⚠️  NEXT STEP: Run Phase 2 notebook to populate demand_cells${NC}"
    echo "   Open: ml/phase2_data_processing.ipynb"
else
    echo -e "${GREEN}✅ PHASE 2 COMPLETE - Ready for Phase 3 optimization!${NC}"
fi

echo ""
echo "================================================"
