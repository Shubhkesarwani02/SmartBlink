# SmartBlink Documentation

## Architecture Overview

### System Design

```
┌─────────────┐
│   Browser   │
│  (Next.js)  │
└──────┬──────┘
       │ HTTP
       ▼
┌─────────────┐      ┌──────────┐
│   FastAPI   │─────▶│  Redis   │
│   Backend   │      │  Cache   │
└──────┬──────┘      └──────────┘
       │
       ▼
┌─────────────┐      ┌──────────┐
│ PostgreSQL  │◀─────│  OSRM    │
│  + PostGIS  │      │ Routing  │
└─────────────┘      └──────────┘
```

### Data Flow

1. **Order Ingestion**
   - Historical orders loaded into PostgreSQL
   - Geocoded and stored with PostGIS geometry

2. **Demand Analysis**
   - Aggregate orders into grid cells
   - Calculate demand heatmap
   - Identify high-density clusters

3. **Optimization**
   - Run clustering algorithms (KMeans, HDBSCAN)
   - Solve facility location problem
   - Rank candidate locations by score

4. **Validation**
   - Query OSRM for travel times
   - Calculate coverage metrics
   - Estimate ROI

5. **Visualization**
   - Render heatmap on Leaflet map
   - Display candidate locations
   - Show coverage zones

## API Design

### RESTful Principles
- Resource-based URLs
- HTTP verbs (GET, POST, PUT, DELETE)
- JSON request/response
- Pagination for large datasets
- Filtering and sorting

### Authentication (Future)
- JWT tokens
- API key for external integrations
- Rate limiting

## Database Schema

See `backend/prisma/schema.prisma` for full schema.

### Key Tables
- **stores**: Physical store locations
- **orders**: Historical order data
- **candidate_locations**: AI-suggested locations
- **demand_grid**: Spatial demand aggregation

### Spatial Queries

```sql
-- Find orders within 5km of a point
SELECT * FROM orders
WHERE ST_DWithin(
  location::geography,
  ST_SetSRID(ST_MakePoint(77.2090, 28.6139), 4326)::geography,
  5000
);

-- Find nearest store to an order
SELECT s.*, ST_Distance(
  s.location::geography,
  o.location::geography
) AS distance
FROM stores s, orders o
WHERE o.id = 123
ORDER BY distance
LIMIT 1;
```

## Deployment

### Local Development
- Use Docker Compose for all services
- Hot reload enabled for backend & frontend

### Production
- **Frontend**: Deploy to Vercel/Netlify
- **Backend**: Deploy to Render/Fly.io/Railway
- **Database**: Use Supabase (free tier) or managed PostgreSQL
- **OSRM**: Optional, can use OpenRouteService API instead

### Environment Setup

**Development:**
```bash
DATABASE_URL=postgresql://smartblink:smartblink123@localhost:5432/smartblink
NEXT_PUBLIC_API_URL=http://localhost:8000
```

**Production:**
```bash
DATABASE_URL=postgresql://user:pass@prod-host:5432/smartblink
NEXT_PUBLIC_API_URL=https://api.smartblink.com
```

## Performance Optimization

### Backend
- Use Redis for caching route results
- Spatial indexes on all geometry columns
- Async I/O with asyncio and asyncpg
- Connection pooling

### Frontend
- Next.js static generation where possible
- Lazy loading for map components
- SWR for client-side caching
- Code splitting

### Database
- Materialized views for aggregated metrics
- Partial indexes for common queries
- VACUUM regularly for PostGIS tables

## Security Best Practices

- Never commit `.env` files
- Use environment variables for secrets
- Validate all input data (Pydantic models)
- Rate limiting on public endpoints
- CORS configured for trusted origins only
- SQL injection prevention (Prisma ORM)
- XSS protection (React escaping)

## Monitoring & Logging

- Structured logging with JSON format
- Health check endpoints
- Error tracking (future: Sentry)
- Performance monitoring (future: DataDog/New Relic)

## Future Enhancements

- Real-time order tracking
- Multi-tenant support for different cities
- A/B testing for optimization algorithms
- Mobile app (React Native)
- Integration with delivery management systems
