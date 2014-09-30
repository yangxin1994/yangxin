class WeiboWorker
  include Sidekiq::Worker

  def perform(year)
    # do something
    Movie.nowplaying.each do |movie|
      spider = OopSpider.new(movie.subject_id)
      begin
        spider.crawl_weibos
      rescue Exception => e
        "Error"
      end
    end
  end
end
# Sidekiq::Cron::Job.create( name: 'Crawling Weibos - every 1 day', cron: '30 9 * * *', klass: 'WeiboWorker')
    # Movie.nowplaying.each do |movie|
    #   spider = OopSpider.new(movie.subject_id)
    #     spider.crawl_weibos 8
    # end