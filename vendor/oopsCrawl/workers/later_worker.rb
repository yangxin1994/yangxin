class LaterWorker
  include Sidekiq::Worker

  def perform
    later_spider = OopSpider.new 
    later_spider.crawl_later

    Movie.each do |m|
      if Time.now.to_i > m.info_show_at
        m.update_attributes(nowplaying:true)
      end   
      if m.subject_url.match(/mtime/)
        unless m.photos.length > 0
          ps = OopSpider.new(m.subject_id.to_s)
          ps.crawl_photos
        end      
      end         
    end
  end
end

Sidekiq::Cron::Job.create( name: 'Crawling Mtime laterplaying - every 1 day', queue: 'quill_movie', cron: '30 4 */1 * *', klass: 'LaterWorker')