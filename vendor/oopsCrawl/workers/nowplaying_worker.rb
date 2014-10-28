class NowplayingWorker
  include Sidekiq::Worker

  def perform
    playing_spider = OopSpider.new 
   	playing_spider.crawl_nowplaying


    Movie.where(subject_url:/mtime\.com/).each do |m|
      unless m.photos.length > 0
        ps = OopSpider.new(m.subject_id.to_s)
        ps.crawl_photos
      end
    end 
  end
end

# Sidekiq::Cron::Job.create( name: 'Crawling Douban nowplaying - every 1 day', cron: '57 11 * * *', klass: 'NowplayingWorker')
Sidekiq::Cron::Job.create( name: 'Crawling Mtime nowplaying - every 12 hours', cron: '* 22 */1 * *', klass: 'NowplayingWorker')
