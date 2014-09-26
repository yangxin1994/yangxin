class NowplayingWorker
  include Sidekiq::Worker

  def perform
    Movie.clear_nowplaying
    all_spider = OopSpider.new 
    all_spider.crawl_nowplaying
  end
end

# Sidekiq::Cron::Job.create( name: 'Crawling Douban nowplaying - every 1 day', cron: '57 11 * * *', klass: 'NowplayingWorker')
Sidekiq::Cron::Job.create( name: 'Crawling Douban nowplaying - every 1 day', cron: '12/8 23 * * *', klass: 'NowplayingWorker')
