-- Analytics Database Schema
-- This schema is optimized for high-volume event ingestion and fast reporting

-- Create events table (raw events storage)
CREATE TABLE IF NOT EXISTS events (
    id BIGSERIAL PRIMARY KEY,
    site_id VARCHAR(255) NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    path VARCHAR(500),
    user_id VARCHAR(255),
    timestamp TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for fast queries
CREATE INDEX idx_events_site_id ON events(site_id);
CREATE INDEX idx_events_timestamp ON events(timestamp);
CREATE INDEX idx_events_site_timestamp ON events(site_id, timestamp);
CREATE INDEX idx_events_user_id ON events(user_id);
CREATE INDEX idx_events_path ON events(path);

-- Create daily aggregation table for faster reporting
CREATE TABLE IF NOT EXISTS daily_stats (
    id BIGSERIAL PRIMARY KEY,
    site_id VARCHAR(255) NOT NULL,
    date DATE NOT NULL,
    total_views INTEGER DEFAULT 0,
    unique_users INTEGER DEFAULT 0,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(site_id, date)
);

-- Create path statistics table
CREATE TABLE IF NOT EXISTS path_stats (
    id BIGSERIAL PRIMARY KEY,
    site_id VARCHAR(255) NOT NULL,
    date DATE NOT NULL,
    path VARCHAR(500) NOT NULL,
    views INTEGER DEFAULT 0,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(site_id, date, path)
);

-- Create indexes for aggregation tables
CREATE INDEX idx_daily_stats_site_date ON daily_stats(site_id, date);
CREATE INDEX idx_path_stats_site_date ON path_stats(site_id, date);

-- Function to update daily statistics
CREATE OR REPLACE FUNCTION update_daily_stats()
RETURNS TRIGGER AS $$
BEGIN
    -- Update daily_stats
    INSERT INTO daily_stats (site_id, date, total_views, unique_users)
    VALUES (
        NEW.site_id,
        DATE(NEW.timestamp),
        1,
        1
    )
    ON CONFLICT (site_id, date)
    DO UPDATE SET
        total_views = daily_stats.total_views + 1,
        updated_at = NOW();
    
    -- Update path_stats
    IF NEW.path IS NOT NULL THEN
        INSERT INTO path_stats (site_id, date, path, views)
        VALUES (
            NEW.site_id,
            DATE(NEW.timestamp),
            NEW.path,
            1
        )
        ON CONFLICT (site_id, date, path)
        DO UPDATE SET
            views = path_stats.views + 1,
            updated_at = NOW();
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update stats (can be disabled for batch processing)
-- CREATE TRIGGER trigger_update_stats
-- AFTER INSERT ON events
-- FOR EACH ROW
-- EXECUTE FUNCTION update_daily_stats();

-- Function to recalculate unique users (run periodically)
CREATE OR REPLACE FUNCTION recalculate_unique_users(p_site_id VARCHAR, p_date DATE)
RETURNS VOID AS $$
BEGIN
    UPDATE daily_stats
    SET unique_users = (
        SELECT COUNT(DISTINCT user_id)
        FROM events
        WHERE site_id = p_site_id
        AND DATE(timestamp) = p_date
        AND user_id IS NOT NULL
    )
    WHERE site_id = p_site_id
    AND date = p_date;
END;
$$ LANGUAGE plpgsql;

-- Create partition for events table (optional, for very high volume)
-- This can be enabled later for better performance
-- CREATE TABLE events_2025_11 PARTITION OF events
-- FOR VALUES FROM ('2025-11-01') TO ('2025-12-01');

-- Grant permissions
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO analytics_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO analytics_user;