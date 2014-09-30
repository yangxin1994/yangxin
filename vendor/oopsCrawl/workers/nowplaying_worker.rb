class NowplayingWorker
  include Sidekiq::Worker

  def perform
    playing_spider = OopSpider.new 
   	playing_spider.crawl_nowplaying
   	Movie.nowplaying.each do |m|
   		photo_spider = OopSpider.new(m.subject_id.to_s)
   		photo_spider.crawl_photos
   	end
  end
end

# Sidekiq::Cron::Job.create( name: 'Crawling Douban nowplaying - every 1 day', cron: '57 11 * * *', klass: 'NowplayingWorker')
Sidekiq::Cron::Job.create( name: 'Crawling Douban nowplaying - every 1 day', cron: '12/8 22 * * *', klass: 'NowplayingWorker')
