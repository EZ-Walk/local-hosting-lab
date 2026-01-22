-- Initialize database for networking learning project

-- Create tables for learning about database networking
CREATE TABLE IF NOT EXISTS network_logs (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    source_ip INET,
    request_path VARCHAR(255),
    response_code INTEGER,
    response_time_ms INTEGER
);

CREATE TABLE IF NOT EXISTS service_health (
    id SERIAL PRIMARY KEY,
    service_name VARCHAR(100) NOT NULL,
    status VARCHAR(50) NOT NULL,
    last_check TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    response_time_ms INTEGER
);

-- Insert some sample data
INSERT INTO network_logs (source_ip, request_path, response_code, response_time_ms) VALUES 
('192.168.1.122', '/api/health', 200, 45),
('192.168.1.122', '/api/users', 200, 120),
('172.20.0.1', '/network-info', 200, 67);

INSERT INTO service_health (service_name, status, response_time_ms) VALUES 
('static-web', 'healthy', 12),
('node-app', 'healthy', 89),
('python-api', 'healthy', 156),
('postgres', 'healthy', 34),
('redis', 'healthy', 8);

-- Create a view for learning about database queries and joins
CREATE VIEW service_overview AS 
SELECT 
    s.service_name,
    s.status,
    s.last_check,
    COUNT(l.id) as request_count,
    AVG(l.response_time_ms) as avg_response_time
FROM service_health s
LEFT JOIN network_logs l ON l.request_path LIKE '%' || s.service_name || '%'
GROUP BY s.service_name, s.status, s.last_check;

-- Grant permissions (user is a reserved keyword, need to quote it)
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO "user";
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO "user";