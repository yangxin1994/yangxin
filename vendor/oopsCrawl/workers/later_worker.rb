class LaterWorker
  include Sidekiq::Worker

  def perform
    later_spider = OopSpider.new 
    later_spider.crawl_later
    Movie.later.each do |m|
    	unless m.photos.length > 0
    		photo_spider = OopSpider.new(m.subject_id.to_s)
    		photo_spider.crawl_photos
    	end
   
    end
  end
end

# Sidekiq::Cron::Job.create( name: 'Crawling Douban nowplaying - every 1 day', cron: '57 11 * * *', klass: 'NowplayingWorker')
Sidekiq::Cron::Job.create( name: 'Crawling Douban later - every 1 day', cron: '12/8 23 * * *', klass: 'LaterWorker')
