with open('server/sockets/auctionEngine.js', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("const Redis = require('ioredis');", "const { getRedisClient } = require('../config/redis');")

old_block = '''let redisClient;
try {
    redisClient = new Redis(process.env.REDIS_URI || 'redis://127.0.0.1:6379');
} catch (e) {
    console.error('[AuctionEngine] Redis connection failed, falling back to memory if needed.', e);
}'''
content = content.replace(old_block, "const redisClient = getRedisClient();")

with open('server/sockets/auctionEngine.js', 'w', encoding='utf-8') as f:
    f.write(content)
