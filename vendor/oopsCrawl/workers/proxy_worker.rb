
class ProxyWorker
  include Sidekiq::Worker

  def perform(year)
    # do something
    begin
      proxy_spider = OopSpider.new
      proxy_spider.crawl_proxies 
    rescue Exception => e
      "Error"
    end   
    movie.update_attribute on_crawl, false
  end
end

Sidekiq::Cron::Job.create( name: 'Crawling ProxyWorker - every 1 day', cron: '7/10 11 * * *', klass: 'ProxyWorker')
