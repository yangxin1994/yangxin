class LaterWorker
  include Sidekiq::Worker

  def perform
    later_spider = OopSpider.new 
    later_spider.crawl_later
    Movie.later.each do |m|
      if Time.now.to_i > m.info_show_at
        m.update_attributes(nowplaying:true)
      end
    	unless m.photos.length > 0
    		photo_spider = OopSpider.new(m.subject_id.to_s)
    		photo_spider.crawl_photos
    	end
   
    end
  end
end

# Sidekiq::Cron::Job.create( name: 'Crawling Douban nowplaying - every 1 day', cron: '57 11 * * *', klass: 'NowplayingWorker')
Sidekiq::Cron::Job.create( name: 'Crawling Douban later - every 1 day', cron: '* */2 * * *', klass: 'LaterWorker')
