require './lib/model/baidu_news'

module Spider

  module News

    def initialize
      @news_spider = MicroSpider.new

      @news_spider.create_action :save do |cresult|
        _cp = {}
        cresult[:field].each { |field| _cp.merge!(field) }
        _cp[:new].each do |_new|
          @movie.baidu_news << BaiduNews.create(_new)
        end
        @movie.save
      end

      super
    end

    def crawl_news
      @news_spider.reset
      @news_spider.delay = 1.5
      learn_news(URI.encode("#{@movie.title_zh} 电影"), @movie.subject_id)
      @news_spider.crawl
      if @movie.baidu_news.latest
        @movie.last_news_crawl = @movie.baidu_news.latest.created_at
        @movie.save
      end
    end  

    def learn_news(key_word, subject_id)
      @news_spider.learn do
        @crawled_pages ||= 0
        site "http://news.baidu.com"
        entrance "/ns?cl=2&rn=20&tn=news&word=#{key_word}&ie=utf-8&ie=utf-8"
        # entrance "?sort=time&start=10003&limit=20"
        
        fields :new, "#content_left li.result" do |new_body|
          movie = Movie.find_by(:subject_id => subject_id)
          _source = new_body.find(">span.c-author").text.split(' ')
          _created_at = _source.pop
          _created_at = _source.pop + ' ' +_created_at
          _source = _source.join
          _created_at = Time.parse(_created_at).to_i
          @is_stop = true if movie.last_news_crawl >= _created_at
          {
            title: new_body.find(">h3.c-title a").text,
            source: _source,
            url: new_body.find(">h3.c-title a").native.attr("href"),
            created_at: _created_at,
            summary: new_body.find(".c-summary").text
          }
        end

        save
        @is_stop = true if (@crawled_pages += 1) > 800
        p "get the page #{@crawled_pages}"
        keep_eyes_on_next_page("#page a.n:contains('下一页')")

      end
    end

    def news
      @news_spider.results.map do |cp| 
        _cp = {}
        cp[:field].each { |field| _cp.merge!(field) }
        _cp
      end
    end

  end

end