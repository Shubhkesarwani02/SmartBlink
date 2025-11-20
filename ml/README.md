# SmartBlink ML Module

This directory contains machine learning algorithms and data processing pipelines for store placement optimization.

## Phase 2: Data Processing & Demand Aggregation

### Quick Start
```bash
# 1. Start Docker services
docker-compose up -d postgres redis

# 2. Activate virtual environment
source venv/bin/activate

# 3. Open notebook in VS Code
# File: ml/phase2_data_processing.ipynb
# Kernel: SmartBlink (venv)
# Run All Cells

# 4. View outputs
open ../outputs/phase2_interactive_map.html
```

### What It Does
- Loads 10K+ orders from PostgreSQL
- Applies H3 hexagonal indexing (resolution 8)
- Aggregates demand by hexagon (order count, avg value, peak hour)
- Calculates distances to nearest store
- Generates visualizations (heatmaps, interactive maps)
- Updates PostGIS demand_cells table

### Documentation
- See `docs/PHASE2_COMPLETE.md` for full guide
- Expected runtime: ~1-2 minutes
- Outputs: `outputs/*.png`, `outputs/*.html`

## Structure

```
ml/
├── phase2_data_processing.ipynb  # Phase 2: Data pipeline (NEW)
├── clustering/         # Clustering algorithms
│   ├── kmeans.py      # KMeans implementation
│   └── hdbscan.py     # HDBSCAN density clustering
├── optimization/      # Location optimization
│   └── facility.py    # Facility location problem solvers
├── utils/            # Utility functions
│   ├── geo.py        # Geospatial helpers
│   └── metrics.py    # Coverage & performance metrics
├── data/             # Data processing
│   └── cache/        # Cached results (gitignored)
└── models/           # Trained models (gitignored)
```

## Algorithms

### 1. Demand Clustering
- **KMeans**: Fast initial clustering of order locations
- **HDBSCAN**: Density-based refinement for irregular patterns

### 2. Facility Location
- **p-median**: Minimize average distance to nearest store
- **k-center**: Minimize maximum distance to any point
- **Greedy coverage**: Iterative selection maximizing coverage

### 3. Metrics
- Coverage area (% within X km/min)
- Average delivery time
- Order fulfillment rate
- ROI estimation

## Usage

```python
from ml.clustering import kmeans_cluster
from ml.optimization import p_median_solver

# Cluster orders
clusters = kmeans_cluster(order_data, n_clusters=10)

# Find optimal locations
candidates = p_median_solver(
    demand_points=order_data,
    n_facilities=5,
    max_distance=5000  # 5km
)
```

## Coming Soon
- Time-series forecasting (Prophet)
- Deep learning for demand prediction
- Multi-objective optimization (NSGA-II)
