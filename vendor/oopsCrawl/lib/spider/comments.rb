require './lib/model/comment'

module Spider

  module Comments

    REG_NUM = /\d+/

    def initialize
      @comments_spider = MicroSpider.new
      @comments_spider.create_action :save do |cresult|
        _cp = {}
        cresult[:field].each { |field| _cp.merge!(field) }
        _cp[:comment].each do |_comment|
          @movie.comments << Comment.create(_comment)
        end
        @movie.save
      end

      super
    end

    def crawl_comments(daily = true)
      @comments_spider.reset
      @comments_spider.delay = 1.5
      learn_comments(@movie.subject_id, daily)
      @comments_spider.crawl
      if @movie.comments.latest
        @movie.last_comment_crawl = @movie.comments.latest.created_at
        @movie.save
      end      
    end

    def subject_id
      @movie.subject_id
    end

    def learn_comments(subject_id, daily)
      @comments_spider.learn do
        @crawled_pages ||= 0

        site "http://movie.douban.com/subject/#{subject_id}/comments"
        if daily
          entrance "?sort=time"
        else
          entrance "?sort=new_score"
        end
        
        # entrance "?sort=time&start=10003&limit=20"
        fields :comment, "#comments .comment" do |comment_body|
          _created_at = Time.parse(comment_body.find(".comment-info span:last").text).to_i
          _rating = nil
          begin
            _rating = REG_NUM.match(comment_body.find(".rating").native.attr("class")).to_s.to_i
          rescue Exception => e
            ""
          end
          movie = Movie.find_by(:subject_id => subject_id)
          @is_stop = true if movie.last_comment_crawl >= _created_at
          {
            user_name: comment_body.find(".comment-info a").text,
            votes: comment_body.find(".comment-vote .votes").text,
            rating: _rating,
            created_at: _created_at,
            content: comment_body.find(">p").text
          }
        end

        save
        @is_stop = true if (@crawled_pages += 1) > 800
        p "get the page #{@crawled_pages}"
        keep_eyes_on_next_page("#paginator a.next") 

      end
    end

    def comments
      @comments_spider.results.map do |cp| 
        _cp = {}
        cp[:field].each { |field| _cp.merge!(field) }
        _cp
      end
    end

  end

end