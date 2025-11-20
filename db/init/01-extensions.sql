-- Enable PostGIS extension
CREATE EXTENSION IF NOT EXISTS postgis;

-- Enable PostGIS topology
CREATE EXTENSION IF NOT EXISTS postgis_topology;

-- Enable PostGIS SFCGAL (for 3D and advanced geometries)
CREATE EXTENSION IF NOT EXISTS postgis_sfcgal;

-- Create a function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';
