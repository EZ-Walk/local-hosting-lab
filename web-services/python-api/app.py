from flask import Flask, jsonify, request
from flask_cors import CORS
import psycopg2
import redis
import socket
import time
import os
import json
from datetime import datetime
from prometheus_client import Counter, Histogram, Gauge, generate_latest, CONTENT_TYPE_LATEST

app = Flask(__name__)
CORS(app)

# Prometheus metrics for learning about monitoring
REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP requests', ['method', 'endpoint', 'status'])
REQUEST_DURATION = Histogram('http_request_duration_seconds', 'HTTP request duration')
ACTIVE_CONNECTIONS = Gauge('active_connections', 'Number of active connections')
DATABASE_CONNECTIONS = Gauge('database_connections', 'Database connection status', ['database'])

# Network learning data storage
network_data = {
    'start_time': datetime.now(),
    'request_count': 0,
    'unique_clients': set(),
    'service_health': {
        'postgres': False,
        'redis': False
    }
}

# Database connections
postgres_conn = None
redis_client = None

def connect_postgres():
    """Learn about database connection management and error handling"""
    global postgres_conn
    try:
        postgres_conn = psycopg2.connect(
            host=os.getenv('POSTGRES_HOST', 'localhost'),
            database=os.getenv('POSTGRES_DB', 'appdb'),
            user=os.getenv('POSTGRES_USER', 'user'),
            password=os.getenv('POSTGRES_PASSWORD', 'password'),
            port=5432
        )
        network_data['service_health']['postgres'] = True
        DATABASE_CONNECTIONS.labels(database='postgres').set(1)
        print("✅ Connected to PostgreSQL")
        return True
    except Exception as e:
        print(f"❌ PostgreSQL connection failed: {e}")
        network_data['service_health']['postgres'] = False
        DATABASE_CONNECTIONS.labels(database='postgres').set(0)
        return False

def connect_redis():
    """Learn about cache layer connections and fallback strategies"""
    global redis_client
    try:
        redis_client = redis.Redis(
            host=os.getenv('REDIS_HOST', 'localhost'),
            port=6379,
            decode_responses=True
        )
        # Test connection
        redis_client.ping()
        network_data['service_health']['redis'] = True
        DATABASE_CONNECTIONS.labels(database='redis').set(1)
        print("✅ Connected to Redis")
        return True
    except Exception as e:
        print(f"❌ Redis connection failed: {e}")
        network_data['service_health']['redis'] = False
        DATABASE_CONNECTIONS.labels(database='redis').set(0)
        return False

@app.before_request
def before_request():
    """Learn about request preprocessing and client tracking"""
    network_data['request_count'] += 1
    client_ip = request.environ.get('HTTP_X_REAL_IP', request.remote_addr)
    network_data['unique_clients'].add(client_ip)
    
    # Update metrics
    ACTIVE_CONNECTIONS.inc()
    print(f"📡 Request from {client_ip} to {request.path}")

@app.after_request
def after_request(response):
    """Learn about response processing and metrics collection"""
    REQUEST_COUNT.labels(
        method=request.method,
        endpoint=request.endpoint or 'unknown',
        status=response.status_code
    ).inc()
    
    ACTIVE_CONNECTIONS.dec()
    return response

@app.route('/health')
def health_check():
    """Health endpoint for load balancer and monitoring"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'services': network_data['service_health'],
        'python_version': os.sys.version
    })

@app.route('/network-info')
def network_info():
    """Learn about network interface inspection and container networking"""
    hostname = socket.gethostname()
    
    # Get network interfaces information
    try:
        # Get container's IP addresses
        host_info = socket.gethostbyname(hostname)
        
        network_info = {
            'hostname': hostname,
            'container_ip': host_info,
            'listening_port': 5000,
            'protocol': 'HTTP/1.1'
        }
    except Exception as e:
        network_info = {
            'hostname': hostname,
            'error': str(e)
        }
    
    return jsonify({
        'container': network_info,
        'stats': {
            'requests_served': network_data['request_count'],
            'unique_clients': len(network_data['unique_clients']),
            'uptime_seconds': (datetime.now() - network_data['start_time']).total_seconds(),
            'services': network_data['service_health']
        },
        'environment': {
            'DATABASE_URL': os.getenv('DATABASE_URL', 'Not set'),
            'REDIS_HOST': os.getenv('REDIS_HOST', 'localhost'),
            'POSTGRES_HOST': os.getenv('POSTGRES_HOST', 'localhost')
        }
    })

@app.route('/api/metrics')
def api_metrics():
    """Learn about service metrics and monitoring data exposure"""
    try:
        # Custom application metrics
        app_metrics = {
            'application': {
                'name': 'python-api-service',
                'version': '1.0.0',
                'uptime_seconds': (datetime.now() - network_data['start_time']).total_seconds(),
                'total_requests': network_data['request_count'],
                'unique_clients': len(network_data['unique_clients'])
            },
            'infrastructure': {
                'hostname': socket.gethostname(),
                'python_version': os.sys.version.split()[0],
                'memory_usage_mb': get_memory_usage()
            },
            'dependencies': {
                'postgres_connected': network_data['service_health']['postgres'],
                'redis_connected': network_data['service_health']['redis']
            }
        }
        
        return jsonify(app_metrics)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/network-test')
def network_test():
    """Learn about inter-service communication and network testing"""
    test_results = {}
    
    # Test database connection
    if postgres_conn:
        try:
            cursor = postgres_conn.cursor()
            cursor.execute("SELECT version(), current_timestamp")
            result = cursor.fetchone()
            cursor.close()
            test_results['postgres'] = {
                'status': 'connected',
                'version': result[0][:50] + '...',
                'timestamp': result[1].isoformat()
            }
        except Exception as e:
            test_results['postgres'] = {
                'status': 'error',
                'error': str(e)
            }
    else:
        test_results['postgres'] = {'status': 'not_connected'}
    
    # Test Redis connection
    if redis_client:
        try:
            test_key = f"network_test_{int(time.time())}"
            redis_client.set(test_key, "test_value", ex=60)
            retrieved = redis_client.get(test_key)
            test_results['redis'] = {
                'status': 'connected',
                'test_successful': retrieved == "test_value",
                'info': redis_client.info('server')['redis_version']
            }
        except Exception as e:
            test_results['redis'] = {
                'status': 'error',
                'error': str(e)
            }
    else:
        test_results['redis'] = {'status': 'not_connected'}
    
    # Test external connectivity (if desired)
    test_results['external'] = test_external_connectivity()
    
    return jsonify({
        'timestamp': datetime.now().isoformat(),
        'tests': test_results
    })

@app.route('/api/simulate-load')
def simulate_load():
    """Learn about load testing and performance monitoring"""
    import threading
    import time
    
    def background_task():
        # Simulate some CPU work
        start = time.time()
        total = 0
        for i in range(100000):
            total += i * i
        duration = time.time() - start
        
        # Store result in Redis if available
        if redis_client:
            redis_client.setex(f"load_test_{int(time.time())}", 300, str(total))
    
    # Start background task
    thread = threading.Thread(target=background_task)
    thread.start()
    
    return jsonify({
        'message': 'Load simulation started',
        'timestamp': datetime.now().isoformat(),
        'note': 'This simulates CPU load and Redis writes for learning purposes'
    })

@app.route('/metrics')
def prometheus_metrics():
    """Prometheus metrics endpoint for monitoring integration"""
    return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}

def get_memory_usage():
    """Simple memory usage estimation"""
    try:
        import resource
        return resource.getrusage(resource.RUSAGE_SELF).ru_maxrss / 1024
    except:
        return 0

def test_external_connectivity():
    """Test connectivity to external services"""
    try:
        import socket
        socket.create_connection(("8.8.8.8", 53), timeout=3)
        return {'status': 'connected', 'target': '8.8.8.8:53'}
    except:
        return {'status': 'failed', 'target': '8.8.8.8:53'}

if __name__ == '__main__':
    print("🐍 Starting Python API service for network learning...")
    
    # Initialize connections
    connect_postgres()
    connect_redis()
    
    print("🚀 Python networking API endpoints:")
    print("   - Health: http://localhost:5000/health")
    print("   - Network Info: http://localhost:5000/network-info")
    print("   - Metrics: http://localhost:5000/api/metrics")
    print("   - Network Test: http://localhost:5000/api/network-test")
    print("   - Simulate Load: http://localhost:5000/api/simulate-load")
    print("   - Prometheus: http://localhost:5000/metrics")
    
    # Run Flask app
    app.run(host='0.0.0.0', port=5000, debug=True)