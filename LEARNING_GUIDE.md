# 🌐 Network Learning Lab Guide

Welcome to your hands-on computer networking learning environment! This lab provides practical experience with networking concepts through real services running on your MacBook.

## 🎯 Learning Objectives

### Layer 2-3 Networking (Network & Data Link)
- **IP Addressing**: Understand how services bind to specific IPs and ports
- **Subnetting**: Explore Docker networks with different CIDR blocks
- **Routing**: Learn how packets flow between containers and your host

### Layer 4 Networking (Transport)
- **TCP vs UDP**: Compare database (TCP) vs caching (TCP) protocols
- **Port Management**: See how different services use different ports
- **Connection Pooling**: Understand how applications manage database connections

### Layer 7 Networking (Application)  
- **HTTP/HTTPS**: Explore REST APIs, status codes, headers
- **DNS Resolution**: Use local DNS entries for service discovery
- **Load Balancing**: Watch Traefik distribute traffic across services

### Service Mesh & Modern Networking
- **Reverse Proxying**: Understand how Traefik routes requests
- **Service Discovery**: See automatic detection of new services
- **Health Checking**: Monitor service availability and recovery
- **Metrics & Monitoring**: Collect and visualize network performance

## 🚀 Getting Started

### 1. Initial Setup
```bash
cd ~/local-hosting-lab
./setup-network-lab.sh start
```

This will:
- Configure local DNS entries (*.local domains)
- Start all services in the correct order
- Run health checks
- Display access URLs

### 2. Explore the Services

#### Static Web Server (nginx)
- **Access**: http://localhost:8080 or http://static.local
- **Learn**: Basic HTTP serving, static content delivery
- **Experiment**: Modify files in `web-services/static/` and reload

#### Node.js API (Express)
- **Access**: http://localhost:8081 or http://api.local
- **Learn**: RESTful APIs, database connections, caching
- **Key Endpoints**:
  - `/health` - Service health check
  - `/network-info` - Container networking details
  - `/test-db` - Database connectivity test
  - `/test-redis` - Cache connectivity test
  - `/api/users` - Sample API with caching

#### Python API (Flask)
- **Access**: http://localhost:8082 or http://python-api.local
- **Learn**: Alternative API implementation, metrics collection
- **Key Endpoints**:
  - `/health` - Service health
  - `/network-info` - Network interface inspection
  - `/api/metrics` - Application metrics
  - `/api/network-test` - Comprehensive connectivity tests
  - `/metrics` - Prometheus metrics format

## 📊 Network Monitoring & Analysis

### Traefik Dashboard
- **Access**: http://localhost:8090
- **Learn**: Request routing, load balancing, service discovery
- **Features**: Live traffic monitoring, service health status

### Grafana Dashboard
- **Access**: http://localhost:3000 (admin/admin)
- **Learn**: Metrics visualization, performance monitoring
- **Setup**: Add Prometheus as data source, create custom dashboards

### Prometheus Metrics
- **Access**: http://localhost:9090
- **Learn**: Time-series data collection, metric queries
- **Explore**: Search for metrics like `http_requests_total`, `response_time`

### NetData Real-time Monitoring
- **Access**: http://localhost:19999
- **Learn**: System-level monitoring, network traffic analysis
- **Features**: Real-time CPU, memory, network, disk metrics

## 🔍 Practical Learning Exercises

### Exercise 1: Network Discovery
```bash
# View running containers and their networks
docker-compose ps
docker network ls
docker network inspect local-hosting-lab_frontend

# Check port bindings
lsof -i -P | grep LISTEN | grep docker

# Analyze network interfaces in containers
docker-compose exec node-app ip addr show
docker-compose exec python-api netstat -tuln
```

### Exercise 2: Service Communication
```bash
# Test service-to-service communication
docker-compose exec node-app curl http://python-api:5000/health
docker-compose exec python-api curl http://node-app:3000/network-info

# Database connectivity from applications
docker-compose exec node-app curl http://localhost:3000/test-db
docker-compose exec python-api curl http://localhost:5000/api/network-test
```

### Exercise 3: Load Testing & Monitoring
```bash
# Generate load on services
for i in {1..100}; do
  curl -s http://localhost:8081/api/users > /dev/null &
  curl -s http://localhost:8082/api/metrics > /dev/null &
done

# Watch metrics in real-time
# Visit Grafana and create dashboards
# Check NetData for system impact
# Monitor Traefik for request distribution
```

### Exercise 4: DNS & Service Discovery
```bash
# Test local DNS resolution
dig static.local
nslookup api.local

# Test service discovery via Traefik
curl -H "Host: api.local" http://localhost/network-info
curl -H "Host: python-api.local" http://localhost/health
```

## 🗄️ Database Learning

### PostgreSQL (Port 5432)
```bash
# Connect to database
docker-compose exec postgres psql -U user -d appdb

# Explore networking tables
SELECT * FROM network_logs;
SELECT * FROM service_health;
SELECT * FROM service_overview;

# Monitor active connections
SELECT * FROM pg_stat_activity;
```

### Redis (Port 6379)
```bash
# Connect to Redis
docker-compose exec redis redis-cli

# Check cached data
KEYS *
GET users:cache

# Monitor Redis performance
INFO stats
```

## 📈 Advanced Networking Concepts

### Container Networking Deep Dive
```bash
# Inspect Docker networks
docker network inspect $(docker network ls -q)

# View network traffic between containers
docker-compose exec netdata cat /proc/net/dev

# Check routing tables
docker-compose exec node-app ip route show
```

### Security & Firewall Learning
```bash
# View container firewall rules (if iptables available)
docker-compose exec node-app iptables -L (may not work in containers)

# Check service ports and bindings
docker-compose exec node-app ss -tulpn
```

## 🛠️ Troubleshooting & Debugging

### Service Issues
```bash
# Check service logs
docker-compose logs -f node-app
docker-compose logs -f python-api
docker-compose logs -f traefik

# Restart services
docker-compose restart node-app
docker-compose restart python-api
```

### Network Issues
```bash
# Test connectivity
docker-compose exec node-app ping postgres
docker-compose exec python-api telnet redis 6379

# Check DNS resolution
docker-compose exec node-app nslookup postgres
```

### Performance Analysis
```bash
# Monitor resource usage
docker stats

# Network performance testing
docker-compose exec node-app curl -w "@curl-format.txt" http://python-api:5000/health
```

## 🎓 Learning Progressions

### Beginner (Week 1)
1. Understand basic service access and health checks
2. Explore the Traefik dashboard and service discovery
3. Learn about different network ports and protocols
4. Practice basic Docker networking commands

### Intermediate (Week 2)
1. Analyze metrics in Prometheus and Grafana
2. Create custom dashboards and alerts
3. Understand load balancing and reverse proxying
4. Experiment with service failures and recovery

### Advanced (Week 3+)
1. Implement custom middleware in Traefik
2. Add TLS/SSL termination for HTTPS
3. Create custom metrics in your applications
4. Build monitoring alerts for network issues
5. Explore container orchestration patterns

## 🔧 Useful Commands

### Quick Start/Stop
```bash
./setup-network-lab.sh start    # Start everything
./setup-network-lab.sh stop     # Stop everything  
./setup-network-lab.sh restart  # Restart everything
./setup-network-lab.sh status   # Check status
./setup-network-lab.sh logs     # View all logs
```

### Individual Service Management
```bash
docker-compose up -d postgres           # Start just database
docker-compose restart traefik          # Restart proxy
docker-compose logs -f python-api       # Follow logs
docker-compose exec node-app bash       # Shell access
```

### Network Analysis
```bash
# Live traffic monitoring
tcpdump -i any port 8080                # Monitor HTTP traffic
netstat -i                              # Interface statistics
iftop                                    # Bandwidth usage by connection
```

## 📚 Additional Resources

- **Docker Networking**: https://docs.docker.com/network/
- **Traefik Documentation**: https://doc.traefik.io/traefik/
- **Prometheus Query Language**: https://prometheus.io/docs/prometheus/latest/querying/
- **Grafana Dashboards**: https://grafana.com/docs/grafana/latest/dashboards/
- **Network Protocols**: https://www.cloudflare.com/learning/network-layer/

## 🎉 Next Steps

1. **Extend the Lab**: Add more services (MongoDB, Elasticsearch, etc.)
2. **Security Learning**: Implement authentication and TLS
3. **Scaling**: Add multiple instances of services for load balancing
4. **Monitoring**: Create comprehensive dashboards for all metrics
5. **Automation**: Build CI/CD pipelines for service deployment

Happy Learning! 🚀