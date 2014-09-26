class MovieWorker
  include Sidekiq::Worker

  def perform(year)
    # do something
    Movie.at_year(year).each do |movie|
      spider = OopSpider.new(movie.subject_id)
      begin
        spider.crawl_reviews 
        spider.crawl_comments 
        # spider.crawl_trailers 
        spider.crawl_photos
        # spider.crawl_news 
        # spider.crawl_weibos
      rescue Exception => e
        "Error"
      end
    end
  end
end