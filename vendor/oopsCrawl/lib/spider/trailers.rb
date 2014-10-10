require './lib/model/trailer'
require './lib/model/trailer_comment'

module Spider

  module Trailers

    REG_NUM = /\d+/

    def initialize
      @trailers_spider = MicroSpider.new

      super
    end

    def crawl_trailers
      @trailers_spider.reset
      @trailers_spider.delay = 1.5
      learn_trailers(@movie.subject_id)
      @trailers_spider.crawl
    end

    def subject_id
      @movie.subject_id
    end

    def learn_trailers(subject_id)
      @trailers_spider.learn do
        site "http://movie.douban.com/subject/#{subject_id}/trailer"
        entrance "/"


        create_action :save_trailer do |cresult|
          _result = {}
          @movie = Movie.where(:subject_id => subject_id).first
          cresult[:field].each { |field| _result.merge!(field) }
          _result[:trailers].each do |_trailer|
            # if trailer = Trailer.where(:trailer_id => _trailer[:trailer_id]).first
              # "跳过~~"
            # else
              trailer = Trailer.create(_trailer)
              @movie.trailers << trailer
            # end
          end
          @movie.save
        end

        fields :trailers, ".video-list li" do |video|
          {
            :title => video.find(">p:first").text,
            :created_at => Time.parse(video.find(".trail-meta span").text).to_i,
            :trailer_id => REG_NUM.match(video.find('a.pr-video').native.attr('href')).to_s
          }
        end

        save_trailer

        follow "a.pr-video" do
          create_action :save_tcomment do |cresult|
            _result = {}
            cresult[:field].each { |field| _result.merge!(field) }
            _result[:comments].each do |comment|
              trailer_comment = TrailerComment.create(comment)
              if @trailer = Trailer.where(:trailer_id => REG_NUM.match(cresult[:entrance]).to_s).first
                @trailer.comments << trailer_comment
                @trailer.save
              else
                ""
              end

            end
          end
          fields :comments, ".report-comment" do |comment_body|
            {
              :content => comment_body.find(">p").text,
              :user_name => comment_body.find(".author a").text,
              :created_at => Time.parse(comment_body.find(".author span").text).to_i
            }
          end
          save_tcomment
        end

      end
    end

    def trailers
      @trailers_spider.results.map do |cp| 
        _cp = {}
        cp[:field].each { |field| _cp.merge!(field) }
        _cp
      end
    end

  end

end