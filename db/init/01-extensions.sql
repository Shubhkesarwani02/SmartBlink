-- Enable PostGIS extension
CREATE EXTENSION IF NOT EXISTS postgis;

-- Enable PostGIS topology
CREATE EXTENSION IF NOT EXISTS postgis_topology;

-- Enable PostGIS SFCGAL (for 3D and advanced geometries)
CREATE EXTENSION IF NOT EXISTS postgis_sfcgal;

-- Enable H3 for hexagonal spatial indexing (optional, if installed)
-- CREATE EXTENSION IF NOT EXISTS h3;
-- CREATE EXTENSION IF NOT EXISTS h3_postgis;

-- Create a function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Helper function: Calculate distance in meters between two points
CREATE OR REPLACE FUNCTION calculate_distance_meters(
    lat1 DOUBLE PRECISION,
    lon1 DOUBLE PRECISION,
    lat2 DOUBLE PRECISION,
    lon2 DOUBLE PRECISION
) RETURNS DOUBLE PRECISION AS $$
BEGIN
    RETURN ST_Distance(
        ST_SetSRID(ST_MakePoint(lon1, lat1), 4326)::geography,
        ST_SetSRID(ST_MakePoint(lon2, lat2), 4326)::geography
    );
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Helper function: Create point from lat/lon
CREATE OR REPLACE FUNCTION make_point_wgs84(
    lat DOUBLE PRECISION,
    lon DOUBLE PRECISION
) RETURNS geometry AS $$
BEGIN
    RETURN ST_SetSRID(ST_MakePoint(lon, lat), 4326);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Helper function: Get lat/lon from geometry
CREATE OR REPLACE FUNCTION extract_lat(geom geometry) 
RETURNS DOUBLE PRECISION AS $$
BEGIN
    RETURN ST_Y(geom);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION extract_lon(geom geometry) 
RETURNS DOUBLE PRECISION AS $$
BEGIN
    RETURN ST_X(geom);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Helper function: Find nearest store to a given point
CREATE OR REPLACE FUNCTION find_nearest_store(
    target_lat DOUBLE PRECISION,
    target_lon DOUBLE PRECISION,
    max_distance_meters DOUBLE PRECISION DEFAULT 50000
) RETURNS TABLE(
    store_id INT,
    store_name TEXT,
    distance_meters DOUBLE PRECISION
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id,
        s.name,
        ST_Distance(
            s.location::geography,
            ST_SetSRID(ST_MakePoint(target_lon, target_lat), 4326)::geography
        ) as distance
    FROM stores s
    WHERE s.is_active = TRUE
        AND ST_DWithin(
            s.location::geography,
            ST_SetSRID(ST_MakePoint(target_lon, target_lat), 4326)::geography,
            max_distance_meters
        )
    ORDER BY distance
    LIMIT 1;
END;
$$ LANGUAGE plpgsql STABLE;

-- Helper function: Count orders within radius of a point
CREATE OR REPLACE FUNCTION count_orders_in_radius(
    center_lat DOUBLE PRECISION,
    center_lon DOUBLE PRECISION,
    radius_meters DOUBLE PRECISION,
    start_date TIMESTAMP DEFAULT NULL,
    end_date TIMESTAMP DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    order_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO order_count
    FROM orders o
    WHERE ST_DWithin(
        o.location::geography,
        ST_SetSRID(ST_MakePoint(center_lon, center_lat), 4326)::geography,
        radius_meters
    )
    AND (start_date IS NULL OR o.timestamp >= start_date)
    AND (end_date IS NULL OR o.timestamp <= end_date);
    
    RETURN order_count;
END;
$$ LANGUAGE plpgsql STABLE;

-- Helper function: Calculate coverage percentage for stores
CREATE OR REPLACE FUNCTION calculate_store_coverage(
    time_threshold_minutes INTEGER DEFAULT 10,
    date_range_days INTEGER DEFAULT 30
) RETURNS TABLE(
    total_orders BIGINT,
    covered_orders BIGINT,
    coverage_percentage NUMERIC
) AS $$
DECLARE
    total_count BIGINT;
    covered_count BIGINT;
BEGIN
    -- Get total orders in date range
    SELECT COUNT(*) INTO total_count
    FROM orders
    WHERE timestamp >= CURRENT_TIMESTAMP - (date_range_days || ' days')::INTERVAL;
    
    -- Get orders covered by active stores within time threshold
    -- (Simplified: using 833 meters per minute as approximate delivery speed)
    SELECT COUNT(*) INTO covered_count
    FROM orders o
    WHERE timestamp >= CURRENT_TIMESTAMP - (date_range_days || ' days')::INTERVAL
        AND EXISTS (
            SELECT 1 FROM stores s
            WHERE s.is_active = TRUE
                AND ST_DWithin(
                    o.location::geography,
                    s.location::geography,
                    time_threshold_minutes * 833.0  -- ~50 km/h in meters per minute
                )
        );
    
    RETURN QUERY SELECT 
        total_count,
        covered_count,
        CASE WHEN total_count > 0 
            THEN ROUND((covered_count::NUMERIC / total_count::NUMERIC) * 100, 2)
            ELSE 0
        END;
END;
$$ LANGUAGE plpgsql STABLE;
