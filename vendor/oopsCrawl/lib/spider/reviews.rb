require './lib/model/review'
require './lib/model/review_comment'

module Spider

  module Reviews

    REG_NUM = /\d+/

    def initialize
      @reviews_spider = MicroSpider.new

      super
    end

    def crawl_reviews
      @reviews_spider.reset
      @reviews_spider.delay = 1.5
      learn_reviews(@movie.subject_id)
      @reviews_spider.crawl
      if @movie.reviews.latest
        @movie.last_review_crawl = @movie.reviews.latest.created_at
        @movie.save
      end
    end

    def learn_reviews(subject_id)
      @reviews_spider.skip_followers = @movie.reviews.map{|review| review.review_url }
      @reviews_spider.learn do
        site "http://movie.douban.com/subject/#{subject_id}/reviews"
        entrance "?filter="
        field :last_review, ".article .review" do |review_body|
          if review_body
            _created_at = review_body.find('.review-hd-info').text.gsub(review_body.find('.review-hd-info a').text, '')
            _created_at = Time.parse(_created_at).to_i
            movie = Movie.find_by(:subject_id => subject_id)
            @is_stop = true if movie.last_review_crawl >= _created_at
          end
        end

        follow ".review .review-hd>h3>a:last" do 

          @latest_comment = nil
          create_action :save_review do |cresult|
            _cp = {}
            # get movie and its latest_review
            movie = Movie.find_by(:subject_id => subject_id)
            cresult[:field].each { |field| _cp.merge!(field) }
            current_review = Review.new(_cp[:review])
            movie.reviews << current_review
            _cp[:comments].each do |comment|
              review_comment = ReviewComment.new(comment)
              @latest_comment ||= current_review.comments.latest
              current_review.comments << review_comment
              review_comment.save
            end
            current_review.save
            movie.save
          end

          field :review, "#content" do |review_body|
            _rating = nil
            begin
              _rating = REG_NUM.match(review_body.find(".main-title-rating").native.attr("class")).to_s.to_i
            rescue Exception => e
              ""
            end  
            _review_id = REG_NUM.match(review_body.find(".main-ft .bn-sharing").native.attr("data-url")).to_s
            {
              :review_id => _review_id,
              :title => review_body.find("h1 span").text,
              :user_name => review_body.find("h1 span").text,
              :votes => review_body.find("#ucount#{_review_id}u"),
              :rating => _rating,
              :content => review_body.find("#link-report>div").text,
              :created_at => Time.parse(review_body.find(".main-hd span.main-meta").text).to_i
            }
          end

          fields :comments, ".main-ft #comments .report-comment" do |comment_body|
            # if comment_body.find(".review-short-ft a")
              
            # end
            {
              :content => comment_body.find(">p").text,
              :user_name => comment_body.find(".author a").text,
              :created_at => Time.parse(comment_body.find(".author span").text).to_i
            }
          end

          save_review
          sleep(1.5)
          keep_eyes_on_next_page(".paginator a.next")

        end
        
        keep_eyes_on_next_page("#paginator a.next")
          
      end
    end

    def reviews
      @reviews_spider.results.map do |cp| 
        _cp = {}
        cp[:field].each { |field| _cp.merge!(field) }
        _cp
      end
    end

  end

end