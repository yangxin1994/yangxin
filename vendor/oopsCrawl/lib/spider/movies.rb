require 'logger'
require './lib/model/movie'

module Spider

  module Movies

    class ::MicroSpider

      def save_movies(cresult, nowplaying = false, is_weibo = false)
        _movie = {}
        cresult[:field].each do |field| 
          _field = {nowplaying: nowplaying}
          field.each do |key, value|
            if value.is_a?(Hash)
              value.each do |k, v|
                _field["#{key}_#{k}".to_sym] = v
              end
            else
              if value.is_a?(Array)
                _field[key] = value.join('/')  # 主演
              else
                if key.to_sym == :info_show_at
                  time_arr = value.gsub(/年|月|日/,',').split(',')
                  _field[key] =  Time.new(time_arr[0],time_arr[1],time_arr[2]).to_i
                else
                  _field[key] = value
                end
              end
            end
          end
          _movie.merge!(_field) 
        end

        exist_movie = Movie.same_movie?(_movie)
        unless exist_movie.present?
          movie_model = Movie.find_or_create_by(:subject_id => _movie[:subject_id])
          begin       
            movie_model.update_attributes(_movie)
            # movie_model.save
          rescue Exception => e
            binding.pry
          end
        end

      end

      def get_content
        # get_count_and_url = lambda do |element|
        #   {
        #     count: /\d+/.match(element.text).to_s.to_i,
        #     url: element.native.attributes['href'].value
        #   }
        # end  
        field :subject, ".db_cover.__r_c_>a" do |element|
          {
            url: element.native.attributes['href'].value + 'posters/hot.html',
            img: element.find('img').native.attributes['src'].value,
            id: /\d+/.match(element.native.attributes['href'].value).to_s
          }
        end

        field :title, '.db_head>div>h1'
        field :info_show_at, ".otherbox.__r_c_ a:last" 
        field :info_directors, ".info_l dd:first a"
        fields :info_actors, '.info_r>dl>dd>p:first>a'

        # field :other_info, '#info' do |element|
        #   # _text = _text.gsub('编剧', 'screenwriters')
        #   # _text = _text.gsub('类型', 'type')
        #   # _text = _text.gsub('制片国家/地区', 'region')
        #   # _text = _text.gsub('语言', 'languages') 
        #   #_text = element.native.text.gsub('导演', 'directors')         
        #   # _text = _text.gsub('主演', 'actors')
        #   # #_text = _text.gsub('上映日期', 'show_at_all')
        #   # _text = _text.gsub(' ', '').split("\n")
        #   # _all_info = {}
        #   # _text.each do |item|
        #   #   if item.present?
        #   #     _item = item.split(':')
        #   #     _all_info[_item[0]] = _item[1]
        #   #   end
        #   # end
        #   # _all_info["show_at"] = Time.parse(_all_info["show_at_all"].split('\'')[0]) if _all_info["show_at_all"]

        #   _all_info
        # end        

        # field :subject_id, 'body' do |element|
        #   t1 = /\d+/.match(element.find("#review_section h2 .pl a").native.attributes['href'].value).to_s
        #   t2 = /\d+/.match(element.find("#mainpic a.nbgnbg").native.attributes['href'].value).to_s
        #   if t1 == t2 then t1 else t2 end
        # end

        #field :trailer, "#related-pic h2 .pl a:first" do |element| get_count_and_url.call(element) end

        #field :comment, '#comments-section h2 .pl a' do |element| get_count_and_url.call(element) end

        #field :review, '#review_section h2 .pl a' do |element| get_count_and_url.call(element) end

        #field :discussion, '.article>h2>a' do |element| get_count_and_url.call(element) end 
          
        # field :content, "#link-report" do |element|
        #   begin
        #     element.find('.all.hidden').text
        #   rescue Exception => e
        #     element.find('span:first').text
        #   end
        # end

        # field :info, '#info' do |element|
        #   # _text = _text.gsub('编剧', 'screenwriters')
        #   # _text = _text.gsub('类型', 'type')
        #   # _text = _text.gsub('制片国家/地区', 'region')
        #   # _text = _text.gsub('语言', 'languages') 
        #   #_text = element.native.text.gsub('导演', 'directors')         
        #   _text = _text.gsub('主演', 'actors')
        #   _text = _text.gsub('上映日期', 'show_at_all')
        #   _text = _text.gsub(' ', '').split("\n")
        #   _all_info = {}
        #   _text.each do |item|
        #     if item.present?
        #       _item = item.split(':')
        #       _all_info[_item[0]] = _item[1]
        #     end
        #   end
        #   # _all_info["show_at"] = Time.parse(_all_info["show_at_all"].split('\'')[0]) if _all_info["show_at_all"]

        #   _all_info
        # end

        # field :rating, '#interest_sectl' do |element|
        #   _text = element.text
        #   case _text 
        #   when "(尚未上映)" || "(评价人数不足)"
        #     {
        #       p: 0,
        #       count: 0,
        #       percent: {},
        #       played: false
        #     }
        #   else
        #     _percent = {}
        #     if _tt = _text.match(/人评价\)([\w\W]*)/)[1]
        #       _tt.split('%').each_with_index do |e, i|
        #         _percent[(5-i).to_s.to_sym] = e.to_f
        #       end
        #     end
        #     {
        #       p: element.find(".rating_self strong").text,
        #       count: element.find("p span[property=\"v:votes\"]").text,
        #       percent: _percent,
        #       played: true
        #     }
        #   end
        # end

        # field :tags, ".tags .tags-body" do |element|
        #   element.text.gsub(' ', '').gsub(/\(\d*\)/, "#").split('#')
        # end

      end
    end


    def initialize
      @movies_spider = MicroSpider.new
      @nowplaying_spider = MicroSpider.new
      @movie_spider = MicroSpider.new

      super
    end

    def crawl_movies_by_year(year = 2014)
      # 伪造ip 没用 @movies_spider.page.driver.browser.agent.request_headers = {"REMOTE_ADDR" => "218.241.178.171"}
      @movies_spider.reset
      learn_movies_by_year(year)
      @movies_spider.crawl
    end

    def crawl_nowplaying(is_weibo = false)
      @nowplaying_spider.reset
      learn_nowplaying(is_weibo)

      @nowplaying_spider.crawl
    end

    def crawl_later(is_weibo = false)
      @nowplaying_spider.reset
      learn_later(is_weibo)
      @nowplaying_spider.crawl
    end


    def crawl_movie(subject_id)
      movie = Movie.find_or_create_by(:subject_id => subject_id)
      @movie_spider.reset
      learn_movie movie.subject_id
      @movie_spider.crawl
    end

    # def learn_nowplaying(is_weibo)
    #   @nowplaying_spider.learn do
    #     site 'http://movie.douban.com/'
    #     entrance "nowplaying"

    #     fields :subject, ".stitle .ticket-btn" do |subject_url|
    #       if _m = Movie.where(:subject_url => subject_url.native.attr("href").gsub("?from=playing_poster",'')).first
    #         _m.nowplaying = true and _m.save
    #       end
    #     end

    #     follow '.stitle .ticket-btn' do
    #       create_action :save do |cresult| self.save_movies(cresult, true, is_weibo) end
    #       self.get_content
    #       save
    #     end
    #   end
    # end

    def learn_nowplaying(is_weibo)
      @nowplaying_spider.learn do
        site 'http://theater.mtime.com/'
        entrance "China_Beijing"
        sub_url = '#hotplayContent .moviemore .othermovie ul li dl dt a.__r_c_'
        fields :subject, "#{sub_url}" do |subject_url|
          if _m = Movie.where(:subject_url => subject_url.native.attr("href")).first
            _m.nowplaying = true and _m.save
          end          
        end
  
        follow "#{sub_url}" do
          create_action :save do |cresult| self.save_movies(cresult, true, is_weibo) end
          self.get_content
          save
        end
      end
    end



    #即将上映
    # def learn_later(is_weibo)
    #   @nowplaying_spider.learn do
    #     site 'http://movie.douban.com/'
    #     entrance "later"

    #     fields :subject, ".intro h3 a" do |subject_url|
    #       if _m = Movie.where(:subject_url => subject_url.native.attr("href")).first
    #         _m.nowplaying = false and _m.save
    #       end
    #     end

    #     follow '.intro h3 a' do
    #       create_action :save do |cresult| self.save_movies(cresult, false, is_weibo) end
    #       self.get_content
    #       save
    #     end
    #   end
    # end


    def learn_later(is_weibo)
      @nowplaying_spider.learn do
        site 'http://theater.mtime.com/'
        entrance "China_Beijing"
        sub_url = '#upcomingSlide ul li.i_wantmovie a.img.__r_c_'
        fields :subject, "#{sub_url}" do |subject_url|
          if _m = Movie.where(:subject_url => subject_url.native.attr("href")).first
            _m.nowplaying = false and _m.save
          end          
        end
  
        follow "#{sub_url}" do
          create_action :save do |cresult| self.save_movies(cresult, false, is_weibo) end
          self.get_content
          save
        end
      end
    end   



    def learn_movie(subject_id)
      # @nowplaying_spider.skip_followers = Movie.all.map{|movie| movie.subject_url + "?from=playing_poster"}
      @movie_spider.learn do
        site 'http://movie.douban.com/subject/'
        entrance "#{subject_id}/?from=playing_poster"

        create_action :save do |cresult| self.save_movies(cresult, true) end
        self.get_content
        save
      end
    end

    def learn_movies_by_year(year)
      @movies_spider.skip_followers = Movie.all.map{|movie| movie.subject_url}
      @movies_spider.learn do
        site 'http://movie.douban.com/'
        entrance "tag/#{year}?type=R"

        keep_eyes_on_next_page(".paginator .next a")

        follow '.article .item .pl2 a' do
          # skip_followers = Movie.all.map{|movie| (movie.subject_url)}
          create_action :save do |cresult| self.save_movies(cresult) end
          self.get_content
          save
        end
      end
    end
  end
end