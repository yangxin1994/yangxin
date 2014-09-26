class NowplayingWorker
  include Sidekiq::Worker

  def perform
    Movie.clear_nowplaying
    all_spider = OopSpider.new
    # # all_spider.crawl_proxies     
    all_spider.crawl_nowplaying
    Movie.nowplaying.each do |movie|
      movie.reload
      next if movie.on_crawl
      spider = OopSpider.new(movie.subject_id)
      begin
        spider.crawl_reviews 
        spider.crawl_comments 
        # spider.crawl_trailers 
        spider.crawl_photos
        spider.crawl_news 
        # spider.crawl_weibo_basics
        # spider.crawl_weibos
      rescue Exception => e
        "Error"
      end
      movie.update_attribute on_crawl, false
    end
  end
end

# Sidekiq::Cron::Job.create( name: 'Crawling Douban nowplaying - every 1 day', cron: '57 11 * * *', klass: 'NowplayingWorker')
Sidekiq::Cron::Job.create( name: 'Crawling Douban nowplaying - every 1 day', cron: '12/8 23 * * *', klass: 'NowplayingWorker')
