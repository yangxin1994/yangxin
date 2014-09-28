class LaterWorker
  include Sidekiq::Worker

  def perform
    later_spider = OopSpider.new 
    later_spider.crawl_later
  end
end

# Sidekiq::Cron::Job.create( name: 'Crawling Douban nowplaying - every 1 day', cron: '57 11 * * *', klass: 'NowplayingWorker')
Sidekiq::Cron::Job.create( name: 'Crawling Douban later - every 1 day', cron: '12/8 23 * * *', klass: 'LaterWorker')
