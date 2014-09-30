require './lib/model/weibo'
require './lib/model/account'
require './lib/model/weibo_user'
require './lib/model/brand'
require './lib/spider/weibo_hacks'
module Spider

  module Weibos

    def initialize
      super
    end

    def crawl_weibos(th = 2)
      weibo_crawler = WeiboCrawler.new(@movie, th)
      weibo_crawler.search
    end

    def crawl_weibos_hot(th = 2)
      weibo_crawler = WeiboCrawler.new(@movie, th)
      weibo_crawler.search_hot
      
    end

    def crawl_weibos_count
      weibo_crawler = WeiboCrawler.new(@movie, 2)
      weibo_crawler.search_day_count
    end

    def crawl_artists
      weibo_crawler = WeiboCrawler.new(@movie, 2)
      weibo_crawler.artists
    end

    def crawl_artists_weibos(th = 2)
      weibo_crawler = WeiboCrawler.new(@movie, th)
      weibo_crawler.weibo_artists
    end

    def crawl_weibo_basic

      weibo_crawler = WeiboCrawler.new(@movie, 2)
      binding.pry

    end
  end

  class WeiboCrawler
    include WeiboHacks
    # SLEEP = 5

    attr_accessor :logger, :cw

    def initialize(movie, thread_counts = 1)
      @fiber_queue = []
      @movie = movie
      @reposts_count = 0
      @logger = Logger.new(STDOUT)
      @accounts = []
      @crawl_threads = []
      @broken_urls = []
      thread_counts = [Account.where(:is_deleted => false).count, thread_counts].min
      while true
        break unless account = Account.get_one
        break if @accounts.include? account
        @accounts << account if account.login
        break if @accounts.length >= thread_counts
      end
    end

    def get_account
      @accounts = @accounts.map do |e|
        if Account.where(:id => e.id).first
          e.reload
        else
          thread_counts = @accounts.length
          @accounts.delete e
          while true
            break unless account = Account.get_one
            next if @accounts.include? account
            e = account 
            break if @accounts.length >= thread_counts
          end
          e
        end
      end
      t = 0
      _outed = false
      while @accounts.map(&:on_crawl).inject(&:&)
        logger.info "> 等待账号: 所有账号都在使用 " unless _outed
        _outed = true
        t += 1
        t = 0 if t > 30 
        sleep(t)
      end
      account = @accounts.shift
      @accounts.push account
      account
    rescue SystemExit, Interrupt
      @accounts.map { |e| e.on_crawl = false;e.save }
      logger.fatal("SystemExit && Interrupt")
      exit!  
    end    

    def get_with_login(url, is_ajax = false)
      account = get_account
      logger.info "> 获取账号: 开始访问: #{url}"
      raise "no account error" unless account
      if ret = account.get_with_login(url, is_ajax)
        if block_given?
          return yield(ret) 
        else
          return ret
        end
      else
        @broken_urls << url
      end
      # @weibos_spider.get(url)
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
        get_with_login("http://s.weibo.com/weibo/#{keyword}?page=1&#{params}") do |page|
          tweets = get_script_html(page, "pl_weibo_direct")
          result[Time.at(show_at).strftime("%F")] = get_field(tweets, ".search_num"){|e| e.text.match(/[\d?\,]+/).to_s.gsub(',','').to_i }
          logger.info(">成功获取: #{Time.at(show_at).strftime("%F")} : #{result[Time.at(show_at).strftime("%F")]}")
          show_at += 1.days
        end
      end
      @movie.weibo_day_count[keyword] = result and @movie.save
      result
    end

    def search_artists_day_count
      @movie.weibo_artists.each do |artist|
        keyword = "#{@movie.title_zh.split(/[：:]/)[0]} #{artist.screen_name}"
        search_day_count(keyword)
      end
    end

    def search_weibo_pres(movies)
      movies.each do |movie|
        next if movie.weibo_count
        keyword ||= movie.title.split(/[：:]/)[0]
        pre_at = movie.show_at - 60.days
        result = 0
        params = biuld_params(
          :keyword    => keyword,
          :starttime  => Time.at(pre_at).strftime("%F-%H"),
          :endtime    => Time.at(movie.show_at).strftime("%F-%H")
        )
        get_with_login("http://s.weibo.com/weibo/#{keyword}?page=1&#{params}") do |page|
          tweets = get_script_html(page, "pl_weibo_direct")
          result = get_field(tweets, ".search_num"){|e| e.text.match(/[\d?\,]+/).to_s.gsub(',','').to_i }
        end
        movie.weibo_count = result
        movie.save
      end
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
        max_page_number = max_page_number.to_i
        max_page_number = 10 if max_page_number > 10 
        get_fields(_followers, '.cnfList .S_line1') do |fol|
          _uid = get_field(fol, ".name>a", "usercard"){|e| e.match(/id=(\d*)/)[1]}
          if get_field(fol, ".name .approve_co").present?
            user = userinfo(_uid)
            wuser.follows << user
            p user
            wuser.save and user.save
          end
        end
      end
    end

    # def fiber_userinfo(uid, is_artist = false)
    #   @fiber_queue << {"uid" => uid, "is_artist" => is_artist}
    #   @crawl_threads << Thread.fork{
    #     user = userinfo(uid, is_artist = false)
    #     if block_given? 
    #       yield(user) if user
    #     else
    #       user
    #     end
    #   }   
    # end

    def user_page(uid, wuser = nil)
      wuser = WeiboUser.find_or_create_by(:wid => uid) if wuser.blank?
      get_with_login("http://weibo.com/u/#{uid}") do |page|
        wuser[:luid] = get_config page, 'page_id'
        v_info = get_script_html(page, 'pl.header.head.index')
        wuser[:follow_count], wuser[:fans_count], wuser[:weibo_count] = get_fields(v_info, ".user_atten strong"){|e| e.text}
        wuser[:fans_count] = get_field(v_info, ".user_atten .S_line1 strong:eq(2)"){|e| e.text } if wuser[:fans_count].blank?
        wuser[:approve] = get_field(v_info, ".pf_verified").present? 
        wuser[:profile_image_url] = get_field(v_info, ".pf_head_pic img"){|e| e.attr("src")}
        wuser[:screen_name] = get_field(v_info, ".pf_name>span"){|e| e.blank? ? "" : e.text} 
        wuser[:screen_name] = get_field(v_info, ".username strong"){|e| e.text} if wuser[:screen_name].blank?
        wuser[:name] = wuser[:screen_name]
        if wuser[:approve_co] = get_field(v_info, ".identity_img").present? 
          wuser[:identity_info] = get_field(v_info, ".identity_info"){|e| e.text.gsub(/[\t\n\r]+/, ' ')}
        end
        wuser.save
      end
    end

    def userinfo(uid, user_type = 0)
      wuser = nil
      _url = ""
      case user_type
      when 0
        _wu = WeiboUser
        _url = "http://weibo.com/p/100505#{uid}/info?from=page_100505&mod=TAB#place"
        wuser = _wu.find_or_create_by(:wid => uid)   
        @movie.weibo_users << wuser
      when 1
        _wu = WeiboUser
        _url = "http://weibo.com/u/#{uid}"
        wuser = _wu.find_or_create_by(:wid => uid)   
        @movie.weibo_users << wuser        
      when 2
        _wu = WeiboArtist
        _url = "http://weibo.com/u/#{uid}"
        wuser = _wu.find_or_create_by(:wid => uid)
        @movie.weibo_artists << wuser
      end
      if wuser.created_at
        wuser.save
        @movie.save
        return wuser 
      end      
      # user_page(uid, wuser)
      # wuser.reload
      get_with_login(_url) do |page|
        wuser[:luid] = get_config page, 'page_id'
        v_info = get_script_html(page, 'pl.header.head.index')
        wuser[:follow_count], wuser[:fans_count], wuser[:weibo_count] = get_fields(v_info, ".user_atten strong"){|e| e.text}
        wuser[:fans_count] = get_field(v_info, ".user_atten .S_line1 strong:eq(2)"){|e| e.text } if wuser[:fans_count].blank?
        wuser[:approve] = get_field(v_info, ".pf_verified").present? 
        wuser[:profile_image_url] = get_field(v_info, ".pf_head_pic img"){|e| e.attr("src")}
        wuser[:screen_name] = get_field(v_info, ".pf_name>span"){|e| e.blank? ? "" : e.text } 
        wuser[:screen_name] = get_field(v_info, ".username strong"){|e| e.text } if wuser[:screen_name].blank?
        wuser[:name] = wuser[:screen_name]
        if wuser[:approve_co] = get_field(v_info, ".identity_img").present? 
          wuser[:identity_info] = get_field(v_info, ".identity_info"){|e| e.text.gsub(/[\t\n\r]+/, ' ')}
        end
        # ####################
        if user_type == 0 && v_info = get_script_html(page, "Pl_Official_LeftInfo__30")
          wuser.update_attributes(set_info(get_fields(v_info, ".infoblock .pf_item")))
        end
        @movie.save
      end
      wuser
    end

    def search_hot(page_number = 1)
      search(:keyword => @movie.title_zh.split(/[：:]/)[0],:xsort => "hot", :page => page_number)
    end

    def search(options = {
        :keyword      => @movie.title_zh.split(/[：:]/)[0],
        :page         => 1
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

      (options[:page]).upto(50) do |_page|
        logger.info ">搜索结果: Page #{_page} ,参数 #{params}"
        page = get_with_login("http://s.weibo.com/wb/#{keyword}?page=#{_page}#{params}&Refer=g")
        tweets = get_script_html(page, "pl_wb_feedlist")
        result["total_num"] = get_field(tweets, ".search_num"){|e| e.text.match(/[\d?\,]+/).to_s.gsub(',','').to_i }
        return if result["total_num"].to_i == 0
        save_weibo(get_fields(tweets, '.feed_list')) do |tweet|
          w = {}
          w[:mid]           = get_attr(tweet, 'mid')
          w[:content]       = get_field(tweet, 'dd.content>p>em'){ |e| e.to_s.gsub(/<[^>]*>/, '')}
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
        tweets = get_script_html(page, "pl_wb_feedlist")
        break if !get_field(tweets,".search_page_M"){|e| e.text.include?("下一页") }
      end
    end

    def save_weibo(tweets)
      saved_tweets = []
      tweets.each do |tweet|
        begin
          w = yield(tweet)
          next unless w[:mid].present?
          # to-do
          w[:created_at] ||= Time.now.to_i
          weibo = Weibo.where(:mid => w[:mid]).first
          weibo = Weibo.create(w) unless weibo
          weibo_user = weibo.weibo_user
          weibo_user ||= userinfo(w[:uid])
          # follower(w[:uid]) if weibo_user.follows.count <= 1
          weibo_user.weibos << weibo
          @movie.weibos << weibo
          weibo_user.save and weibo.save and @movie.save
          saved_tweets << weibo
          logger.info "    > 搜索结果: 用户 #{w[:user_name]} 的信息及微博已保存!"
        rescue Exception => err
          logger.fatal(">提取出错: ")
          logger.fatal(err)
          logger.fatal(err.backtrace.join("\n"))
        end
      end
      saved_tweets.each do |w|
        # follower(w.uid) if weibo_user.follows.count <= 1
        repost(w.uid, w.mid) if (w.reposts_count.to_i > 0 && w.reposts.count < 1)
      end

    end

    def get_follower
      @movie.weibo_users.each do |weibo_user|
        follower(weibo_user.wid) if weibo_user.follows.count <= 1
      end
    end

    def repost(uid, mid)
      return unless post_weibo = Weibo.where(:mid => mid).first
      return unless post_weibo_user = userinfo(uid)
      post_weibo_user.weibos << post_weibo
      post_weibo_user.save
      return if repost_too_deep?
      str = mid_to_str(mid)
      page_number = 1
      max_page_number = 1
      next_page = ""
      while true
        if page_number > 1
          page = get_with_login("http://weibo.com/aj/mblog/info/big?_wv=5&#{next_page}&__rnd=#{rnd}", true) 
          tweets = get_json_html(page)
          max_page_number = get_fields(tweets, ".W_pages_minibtn .page").last
          max_page_number = max_page_number ? max_page_number.text.to_i : 0

          if get_fields(tweets, ".W_pages_minibtn .btn_page_next").present?
            next_page = get_field(tweets, ".W_pages_minibtn .btn_page_next span").attr("action-data")
          else
            next_page = ""
          end
        else
          result = {}
          page = get_with_login("http://weibo.com/#{uid}/#{str}?type=repost#_rnd#{rnd}") 
          tweets = get_script_html(page, "pl.content.weiboDetail.index")
          max_page_number = get_fields(tweets, ".W_pages_minibtn .page").last
          max_page_number = max_page_number ? max_page_number.text.to_i : 0
          _n = get_field(tweets, ".W_pages_minibtn .btn_page_next span")
          if _n.present?
            next_page = _n.attr("action-data")
          end
        end
        page_number += 1
        next unless tweets.present?
        tweets.search('.comment_list').each do |weibo|
          w = {}
          _mid = get_fields(weibo, '.info a').select{|e| e.text.include?("举报")}.first
          if _mid.present?
            w[:mid]               = _mid.attr("onclick").match(/rid=(\d{6,18})/)[1]
          else
            _mids                 = get_fields(weibo, '.info a'){|e| e.attr("action-data")}.map{|e| e.match(/&mid=(\d{6,18})/)}
            _mids                 = _mids.select { |e| e && e[1] != post_weibo.mid.to_s }
            w[:mid]               = _mids.first
          end
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
          w[:url]               = "http://weibo.com/#{w[:uid]}/#{mid_to_str(w[:mid])}"
          if _w = Weibo.where(:mid => w[:mid]).and(:uid => w[:uid]).first
            if @reposts_count >= 1
              next
            else
              _w.update_attributes(w)
            end
            # binding.pry
            # _w.hpost_chain.include? ""
          else
            _w = Weibo.create(w)
          end
          @movie.weibos << _w 
          user = userinfo(w[:uid])
          user.weibos << _w
          logger.info "    > 转发结果: 用户 #{user.name} 的信息及微博已保存!"
          user.save
          post_weibo.reposts << _w unless _w.id == post_weibo.id
          post_weibo.creposts_count += 1
          post_weibo.save; _w.save; @movie.save
          if tweets.search('.comment_list').first.search('.fr a:last').text =~ /转发\(/
            @reposts_count += 1
            logger.info "    > 转发结果: 开始进入第#{@reposts_count}层递归!"
            repost(w[:uid], w[:mid])
            @reposts_count -= 1
          end
        end
        break unless next_page.present?
      end
    end

    def repost_too_deep?
      if @reposts_count > 200
        @reposts_count -= 1
        true
      elsif @reposts_count < 0
        @reposts_count = 0
        false
      else
        false
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
          alist = get_script_html(page, "Pl_Card_UserList__40")
          alist.search("li.pt_li").each do |_at|
            if _u = _at.search(".pic_cont img").first
              _uid = _u.attr("usercard").match(/id=(\d*)/)[1]
            elsif _u = _at.search(".text_info .title>a.S_func1").first
              _uid = _u.attr("usercard").match(/id=(\d*)/)[1]
            else
              p "   ✗ 主创信息: 无法获取主创 id "   
              next
            end            
            uat = userinfo(_uid, 2)
          end 
          if (_apage = alist.search(".opt_page .PCD_btn_next")).present? && alist.search(".PCD_btn_next_disabled").blank?
            apage = _apage.attr("href").value
          else
            break
          end
          @movie.save
        rescue Net::ReadTimeout
          retry if @account.get_proxy
        rescue Exception => e
          # binding.pry
          p "  ✗ 主创信息: 解析出错 #{e}"
        end
      end
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