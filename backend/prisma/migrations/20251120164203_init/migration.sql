-- CreateExtension
CREATE EXTENSION IF NOT EXISTS "postgis";

-- CreateTable
CREATE TABLE "stores" (
    "id" SERIAL NOT NULL,
    "name" TEXT NOT NULL,
    "location" geometry(Point, 4326) NOT NULL,
    "address" TEXT,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "capacity" INTEGER,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "stores_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "orders" (
    "id" SERIAL NOT NULL,
    "location" geometry(Point, 4326) NOT NULL,
    "timestamp" TIMESTAMP(3) NOT NULL,
    "items_count" INTEGER,
    "order_value" DOUBLE PRECISION,
    "customer_id" TEXT,
    "delivered_at" TIMESTAMP(3),
    "store_id" INTEGER,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "orders_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "candidate_locations" (
    "id" SERIAL NOT NULL,
    "location" geometry(Point, 4326) NOT NULL,
    "score" DOUBLE PRECISION NOT NULL,
    "coverage_area_km2" DOUBLE PRECISION NOT NULL,
    "estimated_orders_covered" INTEGER NOT NULL,
    "avg_delivery_time_minutes" DOUBLE PRECISION NOT NULL,
    "roi_estimate" DOUBLE PRECISION,
    "optimization_run_id" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "candidate_locations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "demand_grid" (
    "id" SERIAL NOT NULL,
    "grid_cell" geometry(Polygon, 4326) NOT NULL,
    "demand_score" DOUBLE PRECISION NOT NULL,
    "orders_count" INTEGER NOT NULL,
    "period_start" TIMESTAMP(3) NOT NULL,
    "period_end" TIMESTAMP(3) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "demand_grid_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "stores_location_idx" ON "stores" USING GIST ("location");

-- CreateIndex
CREATE INDEX "orders_location_idx" ON "orders" USING GIST ("location");

-- CreateIndex
CREATE INDEX "orders_timestamp_idx" ON "orders"("timestamp");

-- CreateIndex
CREATE INDEX "candidate_locations_location_idx" ON "candidate_locations" USING GIST ("location");

-- CreateIndex
CREATE INDEX "candidate_locations_score_idx" ON "candidate_locations"("score");

-- CreateIndex
CREATE INDEX "demand_grid_grid_cell_idx" ON "demand_grid" USING GIST ("grid_cell");

-- CreateIndex
CREATE INDEX "demand_grid_period_start_period_end_idx" ON "demand_grid"("period_start", "period_end");
