from fastapi import APIRouter
from app.api.v1 import stores, orders, analytics, optimization

router = APIRouter()

# Include all route modules
router.include_router(stores.router, prefix="/stores", tags=["stores"])
router.include_router(orders.router, prefix="/orders", tags=["orders"])
router.include_router(analytics.router, prefix="/analytics", tags=["analytics"])
router.include_router(optimization.router, prefix="/optimization", tags=["optimization"])
