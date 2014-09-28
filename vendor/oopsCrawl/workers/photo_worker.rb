class PhotoWorker
  include Sidekiq::Worker

  def perform
    Movie.each do |movie|
      spider = OopSpider.new(movie.subject_id)
      begin
        spider.crawl_photos
      rescue Exception => e
        "Error"
      end
    end
  end
end