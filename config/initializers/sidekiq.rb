# Load the redis.yml configuration file
redis_config = YAML.load_file(Rails.root + 'config/redis.yml')[Rails.env]

redis_conn = proc {
  Redis.new host: redis_config['host'], port: redis_config['port']
}
Sidekiq.configure_client do |config|
  config.redis = ConnectionPool.new(size: 5, &redis_conn)
end
Sidekiq.configure_server do |config|
  config.redis = ConnectionPool.new(size: 25, &redis_conn)
end
