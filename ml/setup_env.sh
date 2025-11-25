#!/bin/bash
# SmartBlink ML Environment Setup Script

echo "🚀 Setting up SmartBlink ML Environment..."
echo ""

# Navigate to ML directory
cd "$(dirname "$0")"

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "❌ Virtual environment not found!"
    echo "Creating new virtual environment..."
    python3 -m venv venv
    
    echo "📦 Installing dependencies..."
    source venv/bin/activate
    pip install --upgrade pip setuptools wheel
    pip install -r requirements.txt
    
    echo "🔧 Registering Jupyter kernel..."
    python -m ipykernel install --user --name=smartblink-venv --display-name="Python (SmartBlink)"
    
    echo "✅ Setup complete!"
else
    echo "✅ Virtual environment found"
fi

# Activate environment
source venv/bin/activate

echo ""
echo "📊 Environment Information:"
echo "   Python: $(python --version)"
echo "   Location: $(which python)"
echo ""

# Verify imports
echo "🔍 Verifying installations..."
python -c "
import geopandas as gpd
import h3
import pandas as pd
import numpy as np
print(f'   ✅ GeoPandas: {gpd.__version__}')
print(f'   ✅ H3: {h3.__version__}')
print(f'   ✅ Pandas: {pd.__version__}')
print(f'   ✅ NumPy: {np.__version__}')
"

echo ""
echo "🎉 Environment ready!"
echo ""
echo "To use this environment:"
echo "   1. In VS Code: Select 'Python (SmartBlink)' kernel"
echo "   2. In Terminal: Run 'source venv/bin/activate'"
echo ""
