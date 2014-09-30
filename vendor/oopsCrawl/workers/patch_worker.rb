class PatchWorker
  include Sidekiq::Worker

  def perform(year)
    # do something
    Movie.each do |movie|
      next if movie.on_crawl
      spider = OopSpider.new(movie.subject_id)
      begin
        spider.crawl_reviews if movie.reviews.count <= 20
        spider.crawl_comments  if movie.comments.count <= 20
        # spider.crawl_trailers  if movie.trailers.count <= 3
        spider.crawl_photos if movie.photos.count <= 5
        spider.crawl_news  if movie.news.count <= 5
        # spider.crawl_weibo_basics
        # spider.crawl_weibos
      rescue Exception => e
        "Error"
      end   
      movie.update_attribute :on_crawl, false
    end
  end
end

Sidekiq::Cron::Job.create( name: 'Crawling PatchWorker - every 1 day', cron: '7/10 6 * * *', klass: 'PatchWorker')
