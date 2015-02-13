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

Sidekiq::Cron::Job.create( name: 'Crawling Mtime nowplaying - every 1 day', queue: 'quill_movie', cron: '15 4 */1 * *', klass: 'NowplayingWorker')
