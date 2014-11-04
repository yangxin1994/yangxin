redis_server    = "localhost"
redis_port      = 6379
redis_db_num    = 0
redis_namespace = 'quillCrawl'

Sidekiq.configure_server do |config|
  p redis_server
  config.redis = { url: "redis://#{redis_server}:#{redis_port}/#{redis_db_num}", namespace: redis_namespace }
end

Sidekiq.configure_client do |config|
  config.redis = { url: "redis://#{redis_server}:#{redis_port}/#{redis_db_num}", namespace: redis_namespace }
end