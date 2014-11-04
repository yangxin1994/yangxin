require 'sidekiq'
require 'sidekiq-cron'
require File.expand_path("../../lib/spider", __FILE__)
# require File.expand_path("../../workers/movie_worker", __FILE__)
# require File.expand_path("../../workers/nlpir_worker", __FILE__)
require File.expand_path("../../workers/nowplaying_worker", __FILE__)
require File.expand_path("../../workers/later_worker", __FILE__)
# require File.expand_path("../../workers/photo_worker", __FILE__)
# require File.expand_path("../../workers/patch_worker", __FILE__)
# require File.expand_path("../../workers/weibo_worker", __FILE__)
# require File.expand_path("../../workers/proxy_worker", __FILE__)
