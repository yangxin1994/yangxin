class NowplayingWorker
  include Sidekiq::Worker

  def perform
    playing_spider = OopSpider.new 
   	playing_spider.crawl_nowplaying
  end
end

# Sidekiq::Cron::Job.create( name: 'Crawling Douban nowplaying - every 1 day', cron: '57 11 * * *', klass: 'NowplayingWorker')
Sidekiq::Cron::Job.create( name: 'Crawling Douban nowplaying - every 1 day', cron: '12/8 23 * * *', klass: 'NowplayingWorker')
