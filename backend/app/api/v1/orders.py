from fastapi import APIRouter
from typing import List
from pydantic import BaseModel
from datetime import datetime

router = APIRouter()


class OrderLocation(BaseModel):
    id: int | None = None
    timestamp: datetime
    latitude: float
    longitude: float
    items_count: int | None = None
    order_value: float | None = None


class OrdersResponse(BaseModel):
    orders: List[OrderLocation]
    total: int


@router.get("/", response_model=OrdersResponse)
async def get_orders(
    limit: int = 100,
    offset: int = 0,
    start_date: datetime | None = None,
    end_date: datetime | None = None,
):
    """Get historical order data"""
    # TODO: Fetch from database with filters
    return {
        "orders": [],
        "total": 0
    }


@router.post("/", response_model=OrderLocation)
async def create_order(order: OrderLocation):
    """Create a new order record"""
    # TODO: Save to database
    return order
