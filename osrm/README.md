# OSRM (Open Source Routing Machine)

Local routing engine for calculating travel times and generating isochrones.

## Why OSRM?

- **Fast**: Sub-millisecond routing queries
- **Offline**: No API limits or costs
- **Flexible**: Custom profiles (car, bike, foot)
- **Accurate**: Real road network data

## Setup

### 1. Download OSM Data

```bash
# India extract (~1.5GB)
cd osrm/data
wget https://download.geofabrik.de/asia/india-latest.osm.pbf

# Or specific region (e.g., Delhi)
wget https://download.geofabrik.de/asia/india/delhi-latest.osm.pbf
```

### 2. Process Data

```bash
# Extract
docker run -t -v "${PWD}:/data" osrm/osrm-backend osrm-extract \
  -p /opt/car.lua /data/india-latest.osm.pbf

# Contract
docker run -t -v "${PWD}:/data" osrm/osrm-backend osrm-contract \
  /data/india-latest.osrm

# Or use MLD (faster for large areas)
docker run -t -v "${PWD}:/data" osrm/osrm-backend osrm-partition \
  /data/india-latest.osrm
docker run -t -v "${PWD}:/data" osrm/osrm-backend osrm-customize \
  /data/india-latest.osrm
```

### 3. Start OSRM Server

Uncomment the OSRM service in `docker-compose.yml`:

```yaml
osrm:
  image: osrm/osrm-backend:latest
  container_name: smartblink-osrm
  ports:
    - "5000:5000"
  volumes:
    - ./osrm/data:/data
  command: osrm-routed --algorithm mld /data/india.osrm
```

Then start:
```bash
docker-compose up osrm
```

## Usage

### Route Query
```bash
# From (77.1025,28.7041) to (77.2090,28.6139)
curl "http://localhost:5000/route/v1/driving/77.1025,28.7041;77.2090,28.6139?overview=false"
```

### Distance Table
```bash
# Multiple origins to multiple destinations
curl "http://localhost:5000/table/v1/driving/77.1025,28.7041;77.2090,28.6139?sources=0&destinations=1"
```

### Isochrones (via API)
```python
import requests

# 10-minute isochrone
response = requests.get(
    "http://localhost:5000/isochrone/v1/driving/77.2090,28.6139",
    params={"contours_minutes": "10"}
)
```

## Alternative: OpenRouteService API

If you don't want to run OSRM locally, use ORS free tier:

```python
import requests

ORS_API_KEY = "your_api_key"  # Get from https://openrouteservice.org/

response = requests.post(
    "https://api.openrouteservice.org/v2/isochrones/driving-car",
    headers={"Authorization": ORS_API_KEY},
    json={
        "locations": [[77.2090, 28.6139]],
        "range": [600]  # 10 minutes
    }
)
```

## Resources

- [OSRM Documentation](http://project-osrm.org/)
- [Geofabrik OSM Extracts](https://download.geofabrik.de/)
- [OpenRouteService](https://openrouteservice.org/)
