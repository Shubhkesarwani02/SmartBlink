# 🎯 SmartBlink - Dark Store Placement Optimization

AI-powered heatmap-based system for optimal dark store placement (like Blinkit, Instamart, Zepto). Analyzes demand patterns from historical orders and suggests optimal store locations to maximize coverage and minimize delivery time.

---

## 🌟 Problem Statement

**Goal:** Analyze geospatial order data and predict optimal dark-store locations to maximize population coverage and minimize delivery time & cost.

**Inputs:**
- Historical order records (timestamp, lat/lon, items, value)
- Existing store locations
- Map data (OSM tiles)
- Optional: demographic & traffic layers

**Outputs:**
- Ranked candidate store locations
- Coverage metrics (area, population, % orders within X minutes)
- Delivery time simulations
- ROI estimates

**Success Metrics:**
- Increase % orders served within 10 minutes
- Reduce average travel distance/time
- Store ROI > threshold

---

## 🛠️ Tech Stack

### Backend
- **FastAPI** - High-performance async API framework
- **Python 3.11** - Core language for ML & geospatial
- **Prisma** - Type-safe database ORM with PostGIS support
- **PostgreSQL + PostGIS** - Spatial database for geo queries
- **Redis** - Caching for routing results

### Frontend
- **Next.js 14** - React framework with App Router
- **TypeScript** - Type-safe frontend development
- **Leaflet** - Interactive map visualization
- **Tailwind CSS** - Utility-first styling

### ML & Analytics
- **GeoPandas** - Spatial data operations
- **scikit-learn** - KMeans clustering
- **HDBSCAN** - Density-based clustering
- **OR-Tools** - Facility location optimization (p-median, k-center)

### Mapping & Routing
- **OpenStreetMap** - Free map tiles
- **OSRM** - Open-source routing engine (optional)
- **OpenRouteService** - Isochrones & travel time APIs

### Infrastructure
- **Docker + Docker Compose** - Containerized development
- **Uvicorn** - ASGI server for FastAPI

---

## 📂 Project Structure

```
SmartBlink/
├── backend/              # FastAPI backend
│   ├── app/
│   │   ├── api/v1/      # API routes
│   │   │   ├── stores.py
│   │   │   ├── orders.py
│   │   │   ├── analytics.py
│   │   │   └── optimization.py
│   │   ├── core/        # Config & utilities
│   │   └── main.py      # FastAPI app entry
│   ├── prisma/          # Database schema
│   ├── requirements.txt
│   └── Dockerfile
├── frontend/            # Next.js frontend
│   ├── app/            # App Router pages
│   ├── components/     # React components
│   ├── lib/           # API client & utilities
│   └── package.json
├── db/                 # Database scripts
│   ├── init/          # PostGIS initialization
│   └── README.md
├── ml/                 # ML models & algorithms
├── osrm/              # OSRM routing data (optional)
├── docs/              # Documentation
├── docker-compose.yml
└── README.md
```

---

## 🚀 Quick Start

### Prerequisites

- **Docker** & **Docker Compose** installed
- **Git** for version control
- (Optional) **Node.js 20+** for local frontend dev
- (Optional) **Python 3.11+** for local backend dev

### 1. Clone & Setup

```bash
# Clone the repository
cd SmartBlink

# Copy environment variables
cp .env.example .env

# Edit .env with your settings (optional for local dev)
```

### 2. Start Services with Docker

```bash
# Build and start all services
docker-compose up --build

# Or run in detached mode
docker-compose up -d
```

This will start:
- **PostgreSQL + PostGIS** on port `5432`
- **Redis** on port `6379`
- **FastAPI Backend** on port `8000`
- **Next.js Frontend** on port `3000`

### 3. Access Services

- **Frontend:** http://localhost:3000
- **API Docs:** http://localhost:8000/docs
- **API Health:** http://localhost:8000/health

### 4. Initialize Database

```bash
# Enter backend container
docker-compose exec backend bash

# Generate Prisma client
prisma generate

# Run migrations
prisma migrate dev --name init
```

---

## 🔧 Development

### Backend Development

```bash
# Install dependencies locally (optional)
cd backend
pip install -r requirements.txt

# Run FastAPI with hot reload
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Frontend Development

```bash
# Install dependencies
cd frontend
npm install

# Run Next.js dev server
npm run dev
```

### Database Management

```bash
# View database with Prisma Studio
cd backend
prisma studio

# Create a new migration
prisma migrate dev --name <migration_name>

# Reset database (WARNING: deletes all data)
prisma migrate reset
```

---

## 📊 API Endpoints

### Stores
- `GET /api/v1/stores` - List all stores
- `POST /api/v1/stores` - Create new store
- `GET /api/v1/stores/{id}` - Get store details

### Orders
- `GET /api/v1/orders` - Get historical orders
- `POST /api/v1/orders` - Create order record

### Analytics
- `GET /api/v1/analytics/heatmap` - Generate demand heatmap
- `GET /api/v1/analytics/coverage` - Analyze store coverage

### Optimization
- `POST /api/v1/optimization/find-locations` - Find optimal store locations
- `GET /api/v1/optimization/simulate` - Simulate new store impact

---

## 🗺️ Map Features

The frontend includes:
- **Interactive Map** (OpenStreetMap + Leaflet)
- **Store Markers** - Existing store locations
- **Demand Heatmap** - Order density visualization
- **Coverage Zones** - Delivery radius overlays
- **Candidate Locations** - AI-suggested store placements

---

## 🤖 ML Pipeline (Coming Soon)

1. **Data Preprocessing**
   - Load historical orders
   - Geocode addresses
   - Aggregate demand by grid cells

2. **Clustering**
   - KMeans for initial clustering
   - HDBSCAN for density-based refinement

3. **Optimization**
   - Facility location problem (p-median)
   - Minimize average delivery distance
   - Maximize coverage within time threshold

4. **Validation**
   - Calculate coverage metrics
   - Simulate delivery times
   - Estimate ROI

---

## 🐳 Docker Commands

```bash
# Start services
docker-compose up

# Stop services
docker-compose down

# View logs
docker-compose logs -f backend
docker-compose logs -f frontend

# Rebuild containers
docker-compose up --build

# Remove volumes (clean slate)
docker-compose down -v
```

---

## 📝 Environment Variables

Create a `.env` file in the root directory:

```bash
# Database
DATABASE_URL=postgresql://smartblink:smartblink123@localhost:5432/smartblink

# Redis
REDIS_URL=redis://localhost:6379/0

# External APIs (optional)
OPENROUTE_API_KEY=
NOMINATIM_EMAIL=your-email@example.com

# Frontend
NEXT_PUBLIC_API_URL=http://localhost:8000

# OSRM (if using local routing)
OSRM_URL=http://localhost:5000
```

---

## 🧪 Testing

```bash
# Backend tests (coming soon)
cd backend
pytest

# Frontend tests (coming soon)
cd frontend
npm test
```

---

## 📈 Roadmap

### Phase 0 (Day 0-1) ✅ COMPLETE
- [x] Repository structure
- [x] Docker Compose setup
- [x] FastAPI skeleton
- [x] Next.js skeleton
- [x] Database schema

### Phase 1 (Day 2-3) ✅ COMPLETE
- [x] Complete Prisma schema with all 6 tables
- [x] PostGIS extension with helper functions
- [x] Database migration scripts
- [x] Sample data seeding (10k orders, 5 stores)
- [x] Demand cell generation
- [x] Database connectivity tests

### Phase 2 (Day 4-5) 🚧 IN PROGRESS
- [ ] Load and visualize order data on map
- [ ] Implement heatmap generation from demand cells
- [ ] Coverage analysis endpoints
- [ ] Interactive analytics dashboard

### Phase 3 (Day 6-7)
- [ ] KMeans clustering algorithm
- [ ] HDBSCAN density-based refinement
- [ ] Facility location optimization (p-median)
- [ ] Candidate ranking system

### Phase 4 (Day 8-9)
- [ ] OSRM integration for routing
- [ ] Isochrone generation
- [ ] Delivery time simulation
- [ ] ROI calculator

---

## 🤝 Contributing

1. Create a feature branch
2. Make your changes
3. Test thoroughly
4. Submit a pull request

---

## 📄 License

MIT License - feel free to use this for your projects!

---

## 🔗 Resources

- [FastAPI Docs](https://fastapi.tiangolo.com/)
- [Next.js Docs](https://nextjs.org/docs)
- [PostGIS Documentation](https://postgis.net/documentation/)
- [Leaflet Documentation](https://leafletjs.com/)
- [OpenStreetMap](https://www.openstreetmap.org/)
- [OSRM Backend](http://project-osrm.org/)

---

## 💡 Need Help?

Open an issue or reach out to the maintainers!

**Happy optimizing! 🚀**
