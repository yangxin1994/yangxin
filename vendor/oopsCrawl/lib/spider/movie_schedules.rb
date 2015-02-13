# http://58921.com/alltime/2014?page=1

require './lib/model/movie_schedule'

module Spider

  module MovieSchedules

    def initialize
      @schedules_spider = MicroSpider.new
      @baidu_pres_spider = Mechanize.new
      @staffs_spider = Mechanize.new
      @baidu_pres_spider.user_agent_alias = 'Mac Safari'
      @staffs_spider.user_agent_alias = 'Mac Safari'
      super
    end

    def crawl_schedules(year = 2014)
      @schedules_spider.reset
      @schedules_spider.delay = 1.5
      learn_schedules(year)
      page = @schedules_spider.visit('http://58921.com/user/login')
      @schedules_spider.page.first('#user_login_form').fill_in 'mail', :with => 'xzwyqy@163.com'
      @schedules_spider.page.first('#user_login_form').fill_in 'pass', :with => '1991lamb'
      @schedules_spider.page.first('#user_login_form_type_submit').click 
      @schedules_spider.crawl
    end

    def crawl_staffs
      MovieSchedule.each do |movie|
        next unless movie.title
        next if movie.crawled_staff
        sleep(rand(30) / 10.0)
        begin
          p "> 开始获取: #{movie.title}"
          title = movie.title.gsub(/\([\d\D]+\)/, '')
          l = @staffs_spider.get("http://movie.douban.com/j/subject_suggest?q=#{title}")
          l = JSON.parse(l.body)
          if _mi = l.first
            page = @staffs_spider.get(_mi["url"])
            "property v:initialReleaseDate"
            binding.pry
            movie.types = page.search("#info>span[property=v:genre]").map(&:text)
            page.search("#info>span").each do |span|
              case span.text
              when /导演/
                movie.directors = span.search("a").map(&:text)
                p "> 开始获取: 导演 #{movie.directors.join(',')}"
              when /主演/
                movie.actors = span.search("a").map(&:text)
                p "> 开始获取: 演员 #{movie.actors.join(',')}"
              end
            end
          end 
        rescue Exception => e
          binding.pry
          p "错误: #{e.message}"
        else
          movie.crawled_staff = true
          movie.save
        end
      end
    end

    def learn_schedules(year)
      @schedules_spider.learn do
        site "http://58921.com"
        entrance "/alltime/#{year}"

        create_action :update_schedules do |cresult|
          cresult[:field].each do |field|
            field[:schedule].each do |item|
              next unless item.present?
              id_58921 =  item[:url_58921].match(/m\/(\d+)/)[1] if item[:url_58921]
              next unless m = MovieSchedule.where(:id_58921 => id_58921).first
              if _schedule = item[:schedule].match(/([\d.]+)亿/)
                m[:schedule] = Float(_schedule[1]) * 100_000_000
              elsif _schedule = item[:schedule].match(/([\d.]+)万/)
                m[:schedule] = Float(_schedule[1]) * 10_000
              end
              m.title = item[:title]
              m.is_needed = true if MovieSchedule::MOVIES.include?(m.title.split(/[:：\s]/)[0])
              m.save
            end
          end
        end
        
        fields :schedule, "#content .table-responsive tr" do |tr|
          _info = {}
          next if tr.first('th:eq(1)')
          _info = {
            title: tr.first('td:eq(3)').text,
            url_58921: tr.first('td:eq(3) a').native.attr('href'),
            box_text: tr.first('td:eq(4)').text,
            box_img: tr.first('td:eq(4) img').native.attr('src'),
            schedule: tr.first('td:eq(6)').text,
          }
        end

        follow '#content .table-responsive tr td:eq(3) a' do 
          create_action :save do |cresult|
            item = cresult[:field][0][:info]
            item[:id_58921] = cresult[:entrance].match(/m\/(\d+)/)[1]
            MovieSchedule.create(item)
          end
          field :info, "#content .content_film_view .media-body" do |items|
            info = {}
            items.all('li').each do |item|
              case item.text
              when /总票房/
                if _box = item.text.match(/总票房：\s*([\d.]+)亿/)
                  info[:box] = Float(_box[1]) * 100_000_000
                elsif _box = item.text.match(/总票房：\s*([\d.]+)万/)
                  info[:box] = Float(_box[1]) * 10_000
                end
              when /导演/
                info[:directors] = item.all('a').map{|_a| _a.text}
              when /主演/
                info[:actors] = item.all('a').map{|_a| _a.text}
              when /上映时间/
                info[:show_at] = Time.parse(item.text.match(/上映时间：\s*([\s\S]+)/)[1]).to_i
              end 
            end
            info
          end
          save
        end

        update_schedules
        @page_num ||= 0
        keep_eyes_on_next_page("li.pager_next>a") do |element|
          @all_page_num ||= first("li.pager_last>a")[:href].match(/page=(\d)+/)[1].to_i
          @is_stop = @page_num > @all_page_num
          "/alltime/#{year}?page=#{@page_num += 1}"
        end

      end
    end

    def crawl_baidu_pres(movie)
      _bt = movie.show_at - 60.days
      _et = movie.show_at
      _start = Time.at(_bt).strftime("%F")
      _end = Time.at(_et).strftime("%F")
      _y0, _m0, _d0 = _start.split('-')
      _y1, _m1, _d1 = _end.split('-')
      url = "http://news.baidu.com/ns?from=news&cl=2&bt=#{_bt}&y0=#{_y0}&m0=#{_m0}&d0=#{_d0}&y1=#{_y1}&m1=#{_m1}&d1=#{_d1}&et=#{_et}&q1=#{movie.title}&submit=%B0%D9%B6%C8%D2%BB%CF%C2&q3=&q4=&mt=0&lm=&s=2&begin_date=#{_start}&end_date=#{_end}&tn=newsdy&ct1=1&ct=1&rn=20&q6="
      page = @baidu_pres_spider.get(url)
      movie.baidu_count = page.search(".nums").text.match(/[\d,]+/).to_s.sub(',', '')
      movie.save
    end

    def crawl_weibo_pres
      weibo_crawler = WeiboCrawler.new(@movie, 2)
      weibo_crawler.search_weibo_pres(Movie.needed)
    end

  end

end