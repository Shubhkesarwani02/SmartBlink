# SmartBlink ML Module

This directory contains machine learning algorithms for store placement optimization.

## Structure

```
ml/
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
