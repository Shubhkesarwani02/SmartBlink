#!/bin/bash

# Quick Start Script for SmartBlink Phase 1
# This script sets up the complete database environment

set -e

echo "╔══════════════════════════════════════════════╗"
echo "║   🎯 SmartBlink - Phase 1 Quick Start      ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

echo "✅ Docker is running"
echo ""

# Step 1: Start PostgreSQL and Redis
echo "📦 Step 1: Starting PostgreSQL + Redis..."
docker-compose up -d postgres redis

echo "⏳ Waiting for PostgreSQL to be ready..."
sleep 5

# Check if postgres is ready
until docker-compose exec -T postgres pg_isready -U smartblink > /dev/null 2>&1; do
    echo "  Still waiting..."
    sleep 2
done

echo "✅ PostgreSQL is ready"
echo ""

# Step 2: Setup database
echo "🔧 Step 2: Setting up database schema..."
docker-compose exec -T backend bash -c "cd /app && chmod +x setup_db.sh && ./setup_db.sh" || {
    echo "⚠️  Auto-setup failed. Trying manual setup..."
    docker-compose exec -T backend bash -c "cd /app && prisma generate && prisma db push --skip-generate"
}

echo ""

# Step 3: Test database
echo "🧪 Step 3: Testing database connection..."
docker-compose exec -T backend python test_db.py

echo ""

# Step 4: Check if we should seed
echo "📊 Step 4: Checking data..."
STORE_COUNT=$(docker-compose exec -T postgres psql -U smartblink -d smartblink -t -c "SELECT COUNT(*) FROM stores;" 2>/dev/null | tr -d ' ')

if [ "$STORE_COUNT" = "0" ] || [ -z "$STORE_COUNT" ]; then
    echo ""
    echo "❓ No data found. Would you like to seed sample data? (y/n)"
    read -r response
    
    if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
        echo "🌱 Seeding database with sample data..."
        docker-compose exec -T backend python seed.py
        echo "✅ Sample data seeded"
    else
        echo "⏭️  Skipping data seeding"
    fi
else
    echo "✅ Database already has $STORE_COUNT stores"
fi

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║          ✨ Setup Complete! ✨              ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "📋 Summary:"
echo "  • PostgreSQL + PostGIS: Running on port 5432"
echo "  • Redis: Running on port 6379"
echo "  • Database: All 6 tables created"
echo ""
echo "🚀 Next steps:"
echo "  1. Start backend:  docker-compose up backend"
echo "  2. Start frontend: docker-compose up frontend"
echo "  3. Visit http://localhost:3000"
echo "  4. API docs: http://localhost:8000/docs"
echo ""
echo "📚 Documentation:"
echo "  • Phase 1 Guide: docs/PHASE1_DATABASE_SETUP.md"
echo "  • Full README: README.md"
echo ""
