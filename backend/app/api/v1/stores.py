from fastapi import APIRouter, HTTPException
from typing import List
from pydantic import BaseModel

router = APIRouter()


class StoreLocation(BaseModel):
    id: int | None = None
    name: str
    latitude: float
    longitude: float
    address: str | None = None
    is_active: bool = True


class StoreResponse(BaseModel):
    stores: List[StoreLocation]
    total: int


@router.get("/", response_model=StoreResponse)
async def get_stores():
    """Get all store locations"""
    # TODO: Fetch from database
    return {
        "stores": [],
        "total": 0
    }


@router.post("/", response_model=StoreLocation)
async def create_store(store: StoreLocation):
    """Create a new store location"""
    # TODO: Save to database
    return store


@router.get("/{store_id}", response_model=StoreLocation)
async def get_store(store_id: int):
    """Get a specific store by ID"""
    # TODO: Fetch from database
    raise HTTPException(status_code=404, detail="Store not found")
