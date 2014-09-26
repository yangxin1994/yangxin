require './lib/model/weibo'
require './lib/model/account'
require './lib/model/weibo_user'
require './lib/model/brand'
require './lib/spider/weibo_hacks'
module Spider

  module Weibos

    def initialize
      @crawl_threads = []
      @crawl_objects = []
      super
    end    

    def crawl_weibos(thread_counts = 10)

    end



    def crawl_weibo_basic
      # @movie.weibo_id = '100120172462'
      # @movie.save

      weibo_crawler = WeiboCrawler.new(@movie, 20)
      binding.pry
      # @movie.weibo_artists.each do |wa|
      #   weibo_crawler.search_day_count(@movie.title_zh.split(/[：:]/)[0] + " " + wa.screen_name)
      # end

      # weibo_crawler.change_account
      # weibo_crawler.artists
      # weibo_crawler.artistweibo
      # weibo_crawler.search_hot
      # weibo_crawl.brand
      # weibo_crawl.media
    end

    def crawl_weibo_nowplaying
      weibo_crawler = WeiboCrawler.new(@movie)
      weibo_crawler.change_account
      ids = weibo_crawler.nowplaying
      ids.map do |id_pair|
        m = Movie.find_or_create_by(:subject_id => id_pair[1])
        m.weibo_id = id_pair[0]
        m.save
        crawl_nowplaying(true)
      end
    end

  end

  class WeiboCrawler
    include WeiboHacks
    SLEEP = 5

    attr_accessor :logger, :cw

    def initialize(movie, thread_counts = 1, _cw = nil)
      @cw = _cw
      @movie = movie
      @weibos_spider = Mechanize.new
      @reposts_count = 0
      @weibos_spider.user_agent_alias = 'Mac Safari'
      @account = Account.get_one
      @logger = Logger.new(STDOUT)
      thread_counts = [Account.where(:is_deleted => false).count, thread_counts].min
      @accounts = []
      @crawl_threads = []
      while true
        break unless account = Account.get_one
        break if @accounts.include? account
        @accounts << account if account.login
        break if @accounts.length > thread_counts
      end
      # if @weibo_proxy = @account.get_proxy 
      #   @weibos_spider.set_proxy(@weibo_proxy.ip, @weibo_proxy.port)
      # end
    end

    def get_account
      @accounts.map{|e| e.reload}
      while @accounts.map(&:on_crawl).inject(&:&)
        p "> 等待账号: 所有账号都在使用 "
        sleep(1)
      end
      account = @accounts.shift
      @accounts.push account
      account
    end    

    def get_with_login(url)
      retry_time = 0
      account = get_account
      raise "no account error" unless account
      if ret = account.get_with_login(url)
        yield(ret) if block_given?
        return ret
      else
        @broken_urls << url
        raise "cant get html"
      end
    rescue 
      if retry_time += 1 < 3
        retry
      end
    ensure
      return ret
      # @weibos_spider.get(url)
    end

    def pause_crawl
      @movie.weibo_crawl_status[@cw] = "pause"
      @movie.save
    end

    def crawl_weibos(options = {})
      begin
        @account.update_attribute :on_crawl, true
        search(options)
      rescue Exception => e
        p e
        @movie.weibo_crawl[@cw] = "pause"
        @movie.save
      ensure
        @account.update_attribute :on_crawl, false
      end
    end

    def change_account
     while !login
        @account = Account.get_one
        if @weibo_proxy = @account.get_proxy 
          @weibos_spider.set_proxy(@weibo_proxy.ip, @weibo_proxy.port)
        end             
      end
    end

    def username
      @account.username
    end

    def password
      @account.password
    end

    def login(rel = false)
      if load_cookies && !rel
        # tmp_page = @weibos_spider.get('http://login.sina.com.cn/member/my.php?entry=sso')
        tmp_page = @weibos_spider.get("http://s.weibo.com/weibo")
        if tmp_page.search('a.adv_settiong')[0] && tmp_page.search('a.adv_settiong')[0].text == "帮助"
          p ">登录成功: 通过cookies登录"
          return @is_login = true
        else
          begin
            wlr = tmp_page.search('script').to_s.match(/.replace\([\"\']([\w\W]*)[\"\']\)/)[1]
            tmp_page = @weibos_spider.get(wlr)
            tmp_page.search('a.adv_settiong')[0].text == "帮助"
            p ">登录成功: 通过cookies登录"
            return @is_login = true
          rescue
            ""
          end

        end
      end
      tmp_page = @weibos_spider.post("http://login.sina.com.cn/sso/login.php?client=ssologin.js(v1.4.15)", login_data)
      wlr = tmp_page.search('script').to_s.match(/.replace\([\"\']([\w\W]*)[\"\']\)/)[1]
      after_login_page = @weibos_spider.get(wlr)
      # TODO 判断是否登陆成功
      # parse可能出现异常!!!
      result_json = JSON.try 'parse', (after_login_page.body.match(/\{[\w\W]*\}/).to_s)
      p "a"
      if result_json && result_json["result"]
        save_cookies
        p ">登录成功: 通过账号密码登陆 #{self.username}"
        @is_login = true
      else
        result_json ||= {}
        @errno = result_json["errno"]
        # @account.update_attribute :is_deleted, true
        delete_cookies
        case @errno
        when "4040"
          @account.get_proxy
        when "2070"
        else
        end
        p ">登录失败: #{result_json["errno"]}--#{result_json["reason"]}"
        @is_login = false
        return false
      end
    end

    def cookies
      @weibos_spider.cookie_jar
    end

    def search_day_count(keyword = nil)
      keyword ||= @movie.title_zh.split(/[：:]/)[0]
      show_at = @movie.info_show_at - 3.days
      result = {}
      while show_at <= Time.now.to_i && show_at <= (@movie.info_show_at + 30.days)
        params = biuld_params(
          :keyword    => @movie.title_zh.split(/[：:]/)[0],
          :starttime  => Time.at(show_at).strftime("%F-%H"),
          :endtime    => Time.at(show_at + 1.days).strftime("%F-%H")
        )
        page = get_with_login("http://s.weibo.com/weibo/#{keyword}?page=1&#{params}")
        tweets = get_script_html(page, "pl_weibo_direct")
        if tweets.present? 
          result[Time.at(show_at).strftime("%F")] = get_field(tweets, ".search_num"){|e| e.text.match(/[\d?\,]+/).to_s.gsub(',','').to_i }
        else
          result[Time.at(show_at).strftime("%F")] = 0
        end
        show_at += 1.days
        sleep(30)
      end
      @movie.weibo_day_count[keyword] = result and @movie.save
      result
    end

    def search_hot
      search(:keyword => @movie.title_zh.split(/[：:]/)[0],:xsort => "hot")
    end

    def search(options = {
        :keyword      => @movie.title_zh.split(/[：:]/)[0]
        # :page         => 1,
        # :sorttype     => sorttype,
        # :search_type  => search_type,
        # :searchtime   => searchtime,
        # :msgtype      => msgtype,
        # :search_type  => search_type,
        # :starttime    => starttime
        # :endtime      => endtime,
        # :province     => province,
        # :city         => city,
        # :filter_sources => filter_sources
      })
      keyword ||= @movie.title_zh.split(/[：:]/)[0]
      result = {}
      params = biuld_params(options)

      50.times do |_page|
        logger.info ">搜索结果: Page #{_page + 1} ,参数 #{params}"
        page = get_with_login("http://s.weibo.com/weibo/#{keyword}?page=#{_page + 1}&#{params}") do |page|
          tweets = get_script_html(page, "pl_weibo_direct")
          result["total_num"] = get_field(tweets, ".search_num"){|e| e.text.match(/[\d?\,]+/).to_s.gsub(',','').to_i }
          return if result["total_num"].to_i == 0

          save_weibo(get_fields(tweets, '.feed_list')) do |tweet|
            w = {}
            binding.pry
            w[:mid]           = get_attr(tweet, 'mid')
            w[:content]       = get_field(tweet, 'dd.content>p>em'){ |e| e.to_s.gsub(/<[^>]*>/, '')}
            binding.pry if w[:mid].blank?
            w[:user_name]     = get_field(tweet, '.face>a', 'title')
            w[:created_at]    = get_field(tweet, '.content>p.info>a', 'title'){|e| Time.parse(e).to_i}
            # w[:source]        = get_field(tweet, '.info>a'){|e| e.text}
            w[:uid]           = get_field(tweet, '.face>a', 'href'){|e| e.match(/\d{6,13}/).to_s }
            w[:uid]           = get_field(tweet, '.face>a>img', 'usercard'){|e| e.match(/\d{6,13}/).to_s } if w[:uid].blank?
            w[:weibo_mid]     = get_field(tweet, '.content>p.info>span>a', 'action-data'){|e| e.match(/mid=(\d*)/)[1]}
            w[:reposts_count] = get_field(tweet, '.info>span'){|e| e.text.to_s.match(/转发\((\d+)/)[1]}
            if (_wc = get_field(tweet, '.comment .info>span a:eq(1)')).present?
              w[:content]     = get_field(tweet, '.comment dt em'){|e| e.to_s.gsub(/<[^>]*>/, '')}
              w[:reposts_url] = get_attr(_wc, 'href')
              w[:mid]         = str_to_mid(w[:reposts_url].match(/\/(\w+)\?/)[1])
              w[:uid]         = w[:reposts_url].match(/\d{6,13}/).to_s
            end
            w
          end
        end
        tweets = get_script_html(page, "pl_weibo_direct")
        break if !get_field(tweets,".search_page_M"){|e| e.text.include?("下一页") }
      end
    end

    def save_weibo(tweets)
      tweets.each do |tweet|
        begin
          w = yield(tweet)
          next unless w[:mid].present?

          weibo = Weibo.find_or_create_by(:mid => w[:mid])
          weibo_user = userinfo(w[:uid])
          # follower(w[:uid]) if weibo_user.follows.count <= 1
          weibo_user.weibos << weibo
          @movie.weibos << weibo
          weibo_user.save and weibo.save and @movie.save
          repost(w[:uid], w[:mid]) if w[:reposts_count].to_i > 0
        rescue Exception => err
          logger.fatal(">提取出错: ")
          logger.fatal(err)
          logger.fatal(err.backtrace.join("\n"))
        end
      end
    end

    def fiber_userinfo(uid, is_artist = false)
      @crawl_threads << Thread.fork{
        user = userinfo(uid, is_artist = false)
        if block_given? 
          yield(user) if user
        end
      }   
    end

    def user_page(uid, wuser = nil)
      wuser = WeiboUser.find_or_create_by(:wid => uid) if wuser.blank?
      get_with_login("http://weibo.com/u/#{uid}") do |page|
        wuser[:luid] = get_config page, 'page_id'
        v_info = get_script_html(page, 'pl.header.head.index')
        wuser[:follow_count], wuser[:fans_count], wuser[:weibo_count] = get_fields(v_info, ".user_atten strong"){|e| e.text}
        wuser[:fans_count] = get_field(v_info, ".user_atten .S_line1 strong:eq(2)"){|e| e.text } if wuser[:fans_count].blank?
        wuser[:approve] = get_field(v_info, ".pf_verified").present? 
        wuser[:profile_image_url] = get_field(v_info, ".pf_head_pic img"){|e| e.attr("src")}
        wuser[:screen_name] = get_field(v_info, ".username strong"){|e| e.text}
        wuser[:screen_name] = get_field(v_info, ".pf_name>span"){|e| e.text} if wuser[:screen_name].blank?
        wuser[:name] = wuser[:screen_name]
        if wuser[:approve_co] = get_field(v_info, ".identity_img").present? 
          wuser[:identity_info] = get_field(v_info, ".identity_info"){|e| e.text.gsub(/[\t\n\r]+/, ' ')}
        end
        wuser.save
      end
    end

    def userinfo(uid, is_artist = false)
      _wu = is_artist ? WeiboArtist : WeiboUser
      wuser = _wu.find_or_create_by(:wid => uid)
      @movie.weibo_users << wuser
      if wuser.created_at
        wuser.save
        @movie.save
        return wuser 
      end
      # user_page(uid, wuser)
      # wuser.reload
      get_with_login("http://weibo.com/p/100505#{uid}/info?from=page_100505&mod=TAB#place") do |page|
        wuser[:luid] = get_config page, 'page_id'
        v_info = get_script_html(page, 'pl.header.head.index')
        wuser[:follow_count], wuser[:fans_count], wuser[:weibo_count] = get_fields(v_info, ".user_atten strong"){|e| e.text}
        wuser[:fans_count] = get_field(v_info, ".user_atten .S_line1 strong:eq(2)"){|e| e.text } if wuser[:fans_count].blank?
        wuser[:approve] = get_field(v_info, ".pf_verified").present? 
        wuser[:profile_image_url] = get_field(v_info, ".pf_head_pic img"){|e| e.attr("src")}
        wuser[:screen_name] = get_field(v_info, ".username strong"){|e| e.text}
        wuser[:screen_name] = get_field(v_info, ".pf_name>span"){|e| e.text} if wuser[:screen_name].blank?
        wuser[:name] = wuser[:screen_name]
        if wuser[:approve_co] = get_field(v_info, ".identity_img").present? 
          wuser[:identity_info] = get_field(v_info, ".identity_info"){|e| e.text.gsub(/[\t\n\r]+/, ' ')}
        end

        v_info = get_script_html(page, "pl.header.head.index")
        get_field(v_info, ".infoblock .pf_item") do |user_fields|
          wuser.update_attributes set_info(user_fields)
        end
        @movie.save
        wuser
      end
    end

    def repost(uid, mid)
      return unless post_weibo = Weibo.where(:mid => mid).first
      return unless post_weibo_user = userinfo(uid)
      
    end

    def repost(uid, mid)
      return unless post_weibo = Weibo.where(:mid => mid).first
      return unless post_weibo_user = userinfo(uid)
      p "    > 转发结果: 获取到转发者 #{post_weibo_user.name}"
      post_weibo_user.weibos << post_weibo
      post_weibo_user.save
      # return if post_weibo.reposts.count > 0
      if @reposts_count > 200
        @reposts_count -= 1
        return
      elsif @reposts_count < 0
        @reposts_count = 0
      end
      str = mid_to_str(mid)
      page_number = post_weibo.repost_status
      max_page_number = 1
      next_page = ""
      while page_number <= max_page_number
        if page_number > 1
          begin
            page = get_with_login("http://weibo.com/aj/comment/big?_wv=5&#{next_page}&__rnd=#{rnd}") 
            # too = page.search("script")[11].child.to_s.match(/\{[\w\W]*\}/).to_s
            joo = JSON.parse(page.body)
            tweets = Nokogiri.HTML(joo["data"]["html"])
            # page_number = tweets.search(".W_pages_minibtn .S_txt1").last.text.to_i
            page_number += 1
            if tweets.search(".W_pages_minibtn .page").last.present?
              max_page_number = tweets.search(".W_pages_minibtn .page").last.text.to_i 
            else
              max_page_number = 0
            end
            if tweets.search(".W_pages_minibtn .page").present?
              next_page = tweets.search(".W_pages_minibtn .page").last.attr("action-data").gsub(/page=[\d]*/, "page=#{page_number}")
            # else
              # next_page = tweets.search(".W_pages_minibtn .page").attr("action-data").gsub(/page=[\d]*/, "page=#{page_number}")
            end
          rescue Net::ReadTimeout
            retry if @account.get_proxy            
          rescue Exception => e
            # binding.pry
            p "    ✗ 转发结果: 解析出错 #{e}"
          end    
        else
          begin
            result = {}
            # http://weibo.com/aj/comment/big?_wv=5&id=3734519342963542&max_id=3734694489161700&filter=0&page=2&__rnd=1405905764534
            page = get_with_login("http://weibo.com/#{uid}/#{str}?type=repost#_rnd#{rnd}") 
            page_number += 1
            tweets = get_script_html(page, "pl.content.weiboDetail.index")
            # page_number = tweets.search(".W_pages_minibtn .S_txt1").last.text.to_i
            if tweets.search(".W_pages_minibtn .page").present?
              max_page_number = tweets.search(".W_pages_minibtn .page").last.text.to_i 
            else
              max_page_number = 0
            end
            next_page = tweets.search(".W_pages_minibtn .page").last
            next_page = next_page.attr("action-data").gsub(/page=[\d]*/, "page=#{page_number}") if next_page.present?
          rescue Net::ReadTimeout
            retry if @account.get_proxy            
          rescue Exception => e
            # max_page_number = 0
            # binding.pry
            p "    ✗ 转发结果: 解析出错 #{e}"
          end    
        end
        next unless tweets.present?
        tweets.search('.comment_list').each do |weibo|
          begin
            w = {}
              w[:mid]               = weibo.attributes['mid'].to_s
              w[:content]           = weibo.search('dd>em').to_s.gsub(/<[^>]*>/, '')
              w[:user_name]         = weibo.search('dt>a>img').attr('alt').value
              if weibo.search('.info .fl>em>a').present?
                w[:created_at]      = Time.parse(weibo.search('.info .fl>em>a').attr('title').value).to_i
              else
                w[:created_at]      = Time.parse(weibo.search('.S_txt2').text).to_i
              end
              w[:uid]               = weibo.search('dt>a>img').attr('usercard').value.match(/\d{6,13}/).to_s
              if weibo.search('.info>span>a:last').present?
                w[:weibo_mid]       = weibo.search('.info>span>a:last').attr("action-data").value.match(/mid=(\d+)/)[1]
              else
                w[:weibo_mid]       = weibo.search('.info a').attr("onclick").value.match(/rid=(\d+)/)[1]
              end
            if _w = Weibo.where(:mid => mid).first
            _w.update_attributes(w)
            else
              _w = Weibo.create(w)
            end
            @movie.weibos << _w 
            fiber_userinfo(w[:uid]) do |user|
              user.weibos << _w
              p "    > 转发结果: 用户 #{user.name} 的信息及微博已保存!"
              user.save
            end
            post_weibo.reposts << _w
            post_weibo.creposts_count += 1
            post_weibo.save; _w.save; @movie.save
            if tweets.search('.comment_list').first.search('.fr a:last').text =~ /转发\(/
              p "    > 转发结果: 开始进入第#{@reposts_count += 1}层递归!"
              repost(w[:uid], w[:mid])
            end
          rescue Exception => e
            # binding.pry
            p "    ✗ 转发结果: 解析出错 #{e}"
          end
        end
        post_weibo.repost_status += 1
        post_weibo.save
      end
      post_weibo.repost_status = -1
      post_weibo.save      
      @reposts_count -= 1
    end

    def follower(uid)
      page_number = 0
      max_page_number = 1
      # next_page_url = nil
      return unless wuser = WeiboUser.where(:wid => uid).first
      while page_number <= max_page_number
        page = get_with_login("http://weibo.com/#{uid}/follow?page=#{page_number}#place") 
        _followers = get_script_html(page, "pl.content.followTab.index")
        page_number += 1
        max_page_number = get_fields(_followers, '.W_pages .page'){|e| e.text.to_i}.last
        max_page_number = 10 if max_page_number > 10 
        get_fields(_followers, '.cnfList .S_line1')do |fol|
          _uid = get_field(fol, ".name>a", "usercard"){|e| e.match(/id=(\d*)/)[1]}
          if get_field(fol, ".name .approve_co").present?
            fiber_userinfo(_uid)  do |user|
              wuser.follows << user
              wuser.save and user.save
            end
          end
        end
      end
    end

    def artists
      return unless @movie.weibo_id
      apage = nil
      while true
        begin
          if apage.present?
            page = get_with_login(apage)
          else
            page = get_with_login("http://weibo.com/p/#{@movie.weibo_id}/artist")
          end
          p "✓ 主创信息: 获取到主创页面,准备解析"
          joo = page.search("script")[15].child.to_s.match(/\{[\w\W]*\}/).to_s
          too = page.search("script")[16].child.to_s.match(/\{[\w\W]*\}/).to_s
          # too = page.search("script")[11].child.to_s.match(/\{[\w\W]*\}/).to_s
          joo = JSON.parse(joo)
          too = JSON.parse(too)
          alist = Nokogiri.HTML(joo["html"])
          unless alist.search(".text_info .title>a.S_func1").first
            alist = Nokogiri.HTML(too["html"])
          end
          alist.search(".S_line2").each do |_at|
            if _u = _at.search(".pic_cont img").first
              _uid = _u.attr("usercard").match(/id=(\d*)/)[1]
            elsif _u = _at.search(".text_info .title>a.S_func1").first
              _uid = _u.attr("usercard").match(/id=(\d*)/)[1]
            else
              p "   ✗ 主创信息: 无法获取主创 id "   
              next
            end            
            uat = userinfo(_uid, true)
          end 
          if (_apage = alist.search(".opt_page .PCD_btn_next")).present? && alist.search(".PCD_btn_next_disabled").blank?
            apage = _apage.attr("href").value
          else
            break
          end
        rescue Net::ReadTimeout
          retry if @account.get_proxy
        rescue Exception => e
          # binding.pry

          p "  ✗ 主创信息: 解析出错 #{e}"
        end
      end
    end

    def nowplaying
      ret = []
      next_page = 1
      while true
        p "> 正在上映: 第 #{next_page} 页"
        page = get_with_login("http://movie.weibo.com/movie/site/rank?typeid=9&page=#{next_page}")
        ids = page.search(".W_left dl>dt>a").map { |e| e.attr("href").match(/\/p\/(\d+)/)[1] }
        ids.map do |wid|
          movie_page = get_with_login("http://weibo.com/p/#{wid}")
          script_html = get_script_html(movie_page, "pl.nav.index")
          douban_url = script_html.search(".layer_menu_list ul>li>a").select{|a| a.text == "豆瓣电影"}.first
          sleep(0.5)
          next if douban_url.blank?
          ret << [wid, douban_url.attr("href").match(/\/subject\/(\d+)/)[1]]
        end 
        break unless page.search("#page_next").present?
        next_page +=1
      end
      ret
    end

    def artistweibo(movie_id = nil)
      movie_id ||= @movie.weibo_id
      next_page_url = nil
      i = 0
      while true
        if next_page_url
          page = get_with_login(next_page_url)
          script_json = get_json_html(page)
          break unless script_json.present?
          tweets = script_json.search(".WB_feed_type")
        else
          page = get_with_login("http://weibo.com/p/#{movie_id}/artistweibo")
          script_html = get_script_html(page, "pl.content.homeFeed.index")
          tweets = script_html.search(".PCD_feed_box .WB_feed_type")
        end
        i += 1
        tweets_ary = []
        save_weibo(tweets) do |tweet|
        # tweets.each do |tweet|
          w = {}
          w[:mid]               = tweet.attr('mid').to_s
          w[:content]           = tweet.search('.WB_text').text
          w[:is_artistweibo]    = true
          w[:user_name]         = tweet.search('.WB_name').attr("nick-name").to_s
          w[:created_at]        = Time.parse(tweet.search('.WB_from a:first').text).to_i
          w[:uid]               = tweet.search('.WB_face img').attr('usercard').value.match(/\d{6,13}/).to_s
          w[:reposts_count]     = tweet.search('.WB_handle').text.to_s.match(/转发\((\d+)/).try('[]', 1)
          tweets_ary << w
          w
        end
        next_page_url = "http://weibo.com/p/aj/mblog/mbloglist?_wv=5&domain=100120&pre_page=#{i - 1}&page={i}&max_id=#{tweets_ary.last[:mid]}&end_id=#{tweets_ary.first[:mid]}&count=15&pagebar=0&max_msign=&filtered_min_id=&pl_name=Pl_Core_MixFeed__51&id=#{movie_id}&script_uri=/p/#{movie_id}/artistweibo&feed_type=1&__rnd=#{rnd}"
      end
    end

    def set_info(ary)
      ary = ary.map{|e| e.text.gsub(/[\t\n\r]+/, ':~').gsub(/^:~|:~$/, '').split(':~')}
      w = {}
      _w = {}
      ary.each { |v| _w[v[0]] = v[1] }
      w[:screen_name] ||= _w['昵称']
      w[:name] ||= w[:screen_name]
      w[:gender] = (_w['性别'] == "男" ? 'm' : 'f')
      w[:birth] = _w['生日']
      w[:location] = _w['所在地']
      # w[:screen_name] = _w'[^'] 1)
      w[:company] = _w['公司']
      w[:blood_type] = _w['血型']
      w[:created_at] = _w['注册时间']
      w[:university] = _w['大学']
      w[:mschool] = _w['高中']
      w[:tags] = _w['标签']
      w[:marriage] = _w['感情状况']
      w
    end
  end
end