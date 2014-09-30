class NlpirWorker
  include Sidekiq::Worker

  def perform
    # Movie.clear_nowplaying
    # OopSpider.new.crawl_nowplaying
    Movie.needed_nlpir.each {|e| e.proc_keywords }
    Comment.needed_nlpir.each{|e| e.proc_content}
    Review.needed_nlpir.each{|e| e.proc_content}
    Weibo.needed_nlpir.each{|e| e.proc_content}
    # BaiduNews.needed_nlpir.each{|e| e.proc_content}
    # TrailerComment.needed_nlpir.each{|e| e.proc_content}
    ReviewComment.needed_nlpir.each{|e| e.proc_content}
  end
end

Sidekiq::Cron::Job.create( name: 'Crawling NlpirWorker - every 1 day', cron: '0 22 * * *', klass: 'NlpirWorker')
