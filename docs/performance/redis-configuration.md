# Redis Configuration for Production

This guide explains how to configure Redis as the cache store for Panda CMS in production environments.

## Why Redis?

Redis provides significant performance advantages over the default memory store:

- **Persistent caching** across application restarts
- **Shared cache** across multiple application servers/dynos
- **Better memory management** with configurable eviction policies
- **Production-ready** caching solution used by major platforms

## Quick Start

### 1. Add Redis Gem

If you're using the standard `panda-cms` installation, Redis support is already included via `panda-core`. If not, add to your `Gemfile`:

```ruby
gem "redis", "~> 5.0"
```

Then run:

```bash
bundle install
```

### 2. Configure Cache Store

In `config/environments/production.rb`, configure Rails to use Redis:

```ruby
config.cache_store = :redis_cache_store, {
  url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"),
  namespace: "panda_cms",
  expires_in: 1.hour,

  # Connection pool settings
  pool_size: ENV.fetch("RAILS_MAX_THREADS", 5).to_i,
  pool_timeout: 5,

  # Reconnection settings
  reconnect_attempts: 3,
  reconnect_delay: 0.5,
  reconnect_delay_max: 2.0,

  # Error handling
  error_handler: ->(method:, returning:, exception:) {
    Rails.logger.error("Redis error: #{exception.class} - #{exception.message}")
    # Optionally report to error tracking service (Sentry, Honeybadger, etc.)
  }
}
```

### 3. Set Environment Variable

Set the `REDIS_URL` environment variable to your Redis connection string:

```bash
# Development
export REDIS_URL="redis://localhost:6379/0"

# Production (example for Heroku)
heroku config:set REDIS_URL="redis://your-redis-host:6379/0"
```

## Platform-Specific Setup

### Heroku

1. **Add Redis add-on:**

```bash
heroku addons:create heroku-redis:mini
```

2. **Verify configuration:**

```bash
heroku config:get REDIS_URL
```

The `REDIS_URL` environment variable is automatically set by Heroku.

### Render

1. **Create Redis instance** in Render dashboard
2. **Copy the internal Redis URL**
3. **Add environment variable** to your web service:
   - Key: `REDIS_URL`
   - Value: Your Redis internal URL

### Fly.io

1. **Create Redis instance:**

```bash
flyctl redis create
```

2. **Set connection string:**

```bash
flyctl secrets set REDIS_URL=redis://your-redis-url:6379
```

### Docker/Docker Compose

Add Redis service to your `docker-compose.yml`:

```yaml
services:
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    command: redis-server --appendonly yes

  web:
    # ... your Rails app configuration
    environment:
      REDIS_URL: redis://redis:6379/0
    depends_on:
      - redis

volumes:
  redis_data:
```

## Panda CMS Performance Configuration

Panda CMS provides centralized performance configuration. Update your `config/initializers/panda_cms.rb`:

```ruby
Panda::CMS.configure do |config|
  config.performance = {
    http_caching: {
      enabled: true,
      public: true
    },
    fragment_caching: {
      enabled: true,
      expires_in: 1.hour
    },
    cache_store: {
      type: :redis_cache_store,
      redis_url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"),
      namespace: "panda_cms"
    }
  }
end
```

## Cache Namespacing

Using a namespace prevents cache key collisions if multiple applications share the same Redis instance:

```ruby
config.cache_store = :redis_cache_store, {
  url: ENV["REDIS_URL"],
  namespace: "panda_cms_#{Rails.env}"  # panda_cms_production, panda_cms_staging, etc.
}
```

## Monitoring Redis

### Check Cache Hit Rate

```bash
# Connect to Redis
redis-cli

# Get cache statistics
INFO stats

# Check specific keys
KEYS panda_cms*

# Monitor real-time commands
MONITOR
```

### Memory Usage

```bash
redis-cli INFO memory
```

Look for:
- `used_memory_human`: Current memory usage
- `maxmemory_human`: Memory limit
- `evicted_keys`: Number of evicted keys

## Production Best Practices

### 1. Set Maximum Memory

Configure Redis to use a specific amount of memory and evict old keys when full:

```bash
# In redis.conf or via command line
maxmemory 256mb
maxmemory-policy allkeys-lru
```

### 2. Enable Persistence

For production, enable AOF (Append-Only File) persistence:

```bash
appendonly yes
appendfsync everysec
```

### 3. Connection Pooling

Ensure your connection pool size matches your application threads:

```ruby
config.cache_store = :redis_cache_store, {
  pool_size: ENV.fetch("RAILS_MAX_THREADS", 5).to_i,
  pool_timeout: 5
}
```

### 4. Monitoring & Alerts

Set up monitoring for:
- **Memory usage** approaching limit
- **Eviction rate** increasing
- **Connection errors** or timeouts
- **Hit rate** dropping below 80%

### 5. Separate Redis Instances

For high-traffic sites, consider separate Redis instances for:
- **Cache** (can be volatile, evict old keys)
- **Sidekiq** (needs persistence)
- **Sessions** (needs persistence)

## Troubleshooting

### Connection Refused

```
Redis::CannotConnectError: Error connecting to Redis on localhost:6379
```

**Solution:** Ensure Redis is running and `REDIS_URL` is correctly set.

### Memory Issues

```
OOM command not allowed when used memory > 'maxmemory'
```

**Solution:**
1. Increase Redis `maxmemory`
2. Set appropriate eviction policy
3. Reduce cache expiration times

### Slow Performance

If caching seems slow:

1. **Check network latency** to Redis
2. **Use internal URLs** (not public) on cloud platforms
3. **Enable connection pooling**
4. **Monitor slow queries** with `SLOWLOG`

## Testing Redis Locally

### Install Redis

**macOS:**
```bash
brew install redis
brew services start redis
```

**Ubuntu/Debian:**
```bash
sudo apt-get install redis-server
sudo systemctl start redis
```

### Verify Connection

```ruby
# In Rails console
Rails.cache.write("test", "Hello Redis!")
Rails.cache.read("test")  # => "Hello Redis!"
```

## Performance Comparison

| Cache Store | Persistence | Multi-Server | Performance | Use Case |
|-------------|-------------|--------------|-------------|----------|
| MemoryStore | No | No | Fastest | Development |
| FileStore | Yes | No | Slow | Small sites |
| RedisCache | Yes | Yes | Fast | Production |

## Security

### Authentication

Always use authentication in production:

```bash
# In redis.conf
requirepass your-strong-password

# Connection string
REDIS_URL="redis://:your-strong-password@hostname:6379/0"
```

### TLS/SSL

For connections over the internet, use TLS:

```ruby
config.cache_store = :redis_cache_store, {
  url: ENV["REDIS_URL"],
  ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_PEER }
}
```

## Related Documentation

- [Performance Optimization Guide](../performance.md)
- [Caching Strategy](./caching-strategy.md)
- [Admin Performance Dashboard](./admin-dashboard.md)

## Support

For Redis-specific issues, consult:
- [Redis Documentation](https://redis.io/documentation)
- [Rails Caching Guide](https://guides.rubyonrails.org/caching_with_rails.html)
- [redis-rb Gem Documentation](https://github.com/redis/redis-rb)
