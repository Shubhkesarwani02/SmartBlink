#!/bin/bash

# Database setup and migration script for SmartBlink

set -e

echo "🚀 Setting up SmartBlink database..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if we're in a container or local
if [ -f /.dockerenv ]; then
    echo "📦 Running inside Docker container"
    IN_DOCKER=true
else
    echo "💻 Running on local machine"
    IN_DOCKER=false
fi

# Step 1: Wait for PostgreSQL to be ready
echo -e "\n${YELLOW}⏳ Waiting for PostgreSQL...${NC}"
if [ "$IN_DOCKER" = true ]; then
    until pg_isready -h postgres -U smartblink; do
        echo "  Waiting for postgres..."
        sleep 2
    done
else
    until pg_isready -h localhost -U smartblink; do
        echo "  Waiting for postgres..."
        sleep 2
    done
fi
echo -e "${GREEN}✅ PostgreSQL is ready${NC}"

# Step 2: Verify PostGIS extension
echo -e "\n${YELLOW}🗺️  Verifying PostGIS extension...${NC}"
if [ "$IN_DOCKER" = true ]; then
    PGPASSWORD=smartblink123 psql -h postgres -U smartblink -d smartblink -c "SELECT PostGIS_version();" > /dev/null 2>&1
else
    PGPASSWORD=smartblink123 psql -h localhost -U smartblink -d smartblink -c "SELECT PostGIS_version();" > /dev/null 2>&1
fi

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ PostGIS is installed${NC}"
else
    echo -e "${RED}❌ PostGIS not found. Check db/init scripts.${NC}"
    exit 1
fi

# Step 3: Generate Prisma client
echo -e "\n${YELLOW}🔧 Generating Prisma client...${NC}"
cd /app || exit
prisma generate
echo -e "${GREEN}✅ Prisma client generated${NC}"

# Step 4: Run migrations
echo -e "\n${YELLOW}📝 Running database migrations...${NC}"
prisma db push --skip-generate
echo -e "${GREEN}✅ Migrations completed${NC}"

# Step 5: Verify tables
echo -e "\n${YELLOW}🔍 Verifying tables...${NC}"
EXPECTED_TABLES=("stores" "orders" "demand_cells" "candidates" "optimization_jobs" "isochrones")

for table in "${EXPECTED_TABLES[@]}"; do
    if [ "$IN_DOCKER" = true ]; then
        COUNT=$(PGPASSWORD=smartblink123 psql -h postgres -U smartblink -d smartblink -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_name='$table';")
    else
        COUNT=$(PGPASSWORD=smartblink123 psql -h localhost -U smartblink -d smartblink -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_name='$table';")
    fi
    
    if [ "$COUNT" -eq 1 ]; then
        echo -e "  ${GREEN}✓${NC} $table"
    else
        echo -e "  ${RED}✗${NC} $table (not found)"
    fi
done

# Step 6: Check for existing data
echo -e "\n${YELLOW}📊 Checking for existing data...${NC}"
if [ "$IN_DOCKER" = true ]; then
    STORE_COUNT=$(PGPASSWORD=smartblink123 psql -h postgres -U smartblink -d smartblink -t -c "SELECT COUNT(*) FROM stores;")
else
    STORE_COUNT=$(PGPASSWORD=smartblink123 psql -h localhost -U smartblink -d smartblink -t -c "SELECT COUNT(*) FROM stores;")
fi

if [ "$STORE_COUNT" -eq 0 ]; then
    echo -e "${YELLOW}⚠️  No data found. Run 'python seed.py' to populate database.${NC}"
else
    echo -e "${GREEN}✅ Database has $STORE_COUNT stores${NC}"
fi

echo -e "\n${GREEN}🎉 Database setup completed successfully!${NC}"
echo -e "\n${YELLOW}Next steps:${NC}"
echo "  1. Start the backend: uvicorn app.main:app --reload"
echo "  2. Seed data (if needed): python seed.py"
echo "  3. View API docs: http://localhost:8000/docs"
