const express = require('express');
const cors = require('cors');
const redis = require('redis');
const { Client } = require('pg');
const os = require('os');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Network information storage
let networkStats = {
    startTime: new Date(),
    requests: 0,
    uniqueIPs: new Set(),
    services: {
        redis: 'disconnected',
        postgres: 'disconnected'
    }
};

// Redis connection
let redisClient;
async function connectRedis() {
    try {
        redisClient = redis.createClient({
            host: process.env.REDIS_HOST || 'localhost',
            port: 6379
        });
        await redisClient.connect();
        networkStats.services.redis = 'connected';
        console.log('✅ Connected to Redis');
    } catch (error) {
        console.log('❌ Redis connection failed:', error.message);
        networkStats.services.redis = 'failed';
    }
}

// PostgreSQL connection
let pgClient;
async function connectPostgres() {
    try {
        pgClient = new Client({
            host: process.env.DB_HOST || 'localhost',
            port: 5432,
            database: 'appdb',
            user: 'user',
            password: 'password'
        });
        await pgClient.connect();
        networkStats.services.postgres = 'connected';
        console.log('✅ Connected to PostgreSQL');
    } catch (error) {
        console.log('❌ PostgreSQL connection failed:', error.message);
        networkStats.services.postgres = 'failed';
    }
}

// Middleware to track requests and IPs
app.use((req, res, next) => {
    networkStats.requests++;
    const clientIP = req.ip || req.connection.remoteAddress || req.headers['x-forwarded-for'];
    networkStats.uniqueIPs.add(clientIP);
    console.log(`📡 Request from ${clientIP} to ${req.path}`);
    next();
});

// Routes for learning networking concepts

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        services: networkStats.services
    });
});

// Network information endpoint
app.get('/network-info', async (req, res) => {
    const networkInterfaces = os.networkInterfaces();
    
    // Get container network info
    const containerNetworkInfo = {
        hostname: os.hostname(),
        platform: os.platform(),
        architecture: os.arch(),
        interfaces: Object.keys(networkInterfaces).map(name => ({
            name,
            addresses: networkInterfaces[name].map(addr => ({
                address: addr.address,
                family: addr.family,
                internal: addr.internal
            }))
        }))
    };

    res.json({
        container: containerNetworkInfo,
        stats: {
            ...networkStats,
            uniqueIPs: Array.from(networkStats.uniqueIPs),
            uptime: Date.now() - networkStats.startTime.getTime()
        },
        environment: {
            NODE_ENV: process.env.NODE_ENV,
            DB_HOST: process.env.DB_HOST,
            REDIS_HOST: process.env.REDIS_HOST
        }
    });
});

// Test database connectivity
app.get('/test-db', async (req, res) => {
    try {
        if (!pgClient) {
            throw new Error('PostgreSQL client not initialized');
        }
        
        const result = await pgClient.query('SELECT NOW() as current_time, version() as postgres_version');
        res.json({
            success: true,
            database: 'PostgreSQL',
            data: result.rows[0]
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Test Redis connectivity
app.get('/test-redis', async (req, res) => {
    try {
        if (!redisClient) {
            throw new Error('Redis client not initialized');
        }
        
        const testKey = 'network-test';
        const testValue = `Test from ${Date.now()}`;
        
        await redisClient.set(testKey, testValue);
        const retrievedValue = await redisClient.get(testKey);
        
        res.json({
            success: true,
            database: 'Redis',
            data: {
                stored: testValue,
                retrieved: retrievedValue,
                match: testValue === retrievedValue
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// API endpoint to demonstrate service-to-service communication
app.get('/api/users', async (req, res) => {
    try {
        // Simulate fetching users from database
        const users = [
            { id: 1, name: 'Network Admin', role: 'Administrator', lastLogin: new Date() },
            { id: 2, name: 'API User', role: 'Developer', lastLogin: new Date() },
            { id: 3, name: 'Monitor Service', role: 'Service Account', lastLogin: new Date() }
        ];

        // Cache in Redis if available
        if (redisClient) {
            await redisClient.setEx('users:cache', 300, JSON.stringify(users));
        }

        res.json({
            success: true,
            data: users,
            metadata: {
                count: users.length,
                cached: !!redisClient,
                timestamp: new Date().toISOString()
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// WebSocket-like endpoint for real-time network stats
app.get('/stream/stats', (req, res) => {
    res.setHeader('Content-Type', 'text/plain');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');

    const sendStats = () => {
        const stats = {
            timestamp: new Date().toISOString(),
            activeConnections: networkStats.requests,
            uniqueClients: networkStats.uniqueIPs.size,
            uptime: Date.now() - networkStats.startTime.getTime(),
            memory: process.memoryUsage(),
            services: networkStats.services
        };
        
        res.write(`data: ${JSON.stringify(stats)}\n\n`);
    };

    const interval = setInterval(sendStats, 1000);
    sendStats(); // Send initial stats

    req.on('close', () => {
        clearInterval(interval);
    });
});

// Start server and connect to services
async function startServer() {
    await connectRedis();
    await connectPostgres();
    
    app.listen(PORT, '0.0.0.0', () => {
        console.log(`🚀 Node.js networking server running on port ${PORT}`);
        console.log(`🔍 Network learning endpoints:`);
        console.log(`   - Health: http://localhost:${PORT}/health`);
        console.log(`   - Network Info: http://localhost:${PORT}/network-info`);
        console.log(`   - Test DB: http://localhost:${PORT}/test-db`);
        console.log(`   - Test Redis: http://localhost:${PORT}/test-redis`);
        console.log(`   - API Users: http://localhost:${PORT}/api/users`);
        console.log(`   - Live Stats: http://localhost:${PORT}/stream/stats`);
    });
}

startServer().catch(console.error);