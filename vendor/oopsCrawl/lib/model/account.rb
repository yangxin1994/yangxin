# encoding: utf-8
require File.expand_path("../../spider/weibo_hacks", __FILE__) 
class Account
  include Mongoid::Document
  include WeiboHacks

  field :access_token,          :type => String
  field :code,                  :type => String
  field :uid,                   :type => String
  field :username,              :type => String
  field :password,              :type => String

  field :location,              :type => String

  field :auth_key,              :type => String
  field :last_use,              :type => Integer, :default => Time.now.to_i
  field :last_api_use,          :type => Integer, :default => Time.now.to_i
  field :api_used,              :type => Integer, :default => 0
  field :is_deleted,            :type => Boolean, :default => false

  field :on_crawl,              :type => Boolean, :default => false

  belongs_to :proxy

  SLEEP_TIME = 10


  # # # # # # # # # # # # # # # #
  #
  # 从这里开始是类方法
  #
  # # # # # # # # # # # # # # # #

  def self.access_weibo(code)
    # 目前只有新浪
    data = {
      'client_id'     => Oauth2::WEIBO_CLIENT_ID,
      'client_secret' => Oauth2::WEIBO_CLIENT_SECRET ,
      'grant_type'    => 'authorization_code',
      'redirect_uri'  => Oauth2::WEIBO_CALLBACK_URL,
      'code'          => code}
    result = Utility.post_j 'https://api.weibo.com/oauth2/access_token', data
    if result["uid"]
      if uw = Utility::Weibo.where(:uid => result["uid"]).first
        uw.access_token = result["access_token"]
        uw.expires_in   = Time.now + result["expires_in"].to_i
        uw.status.each do |k, v|
          uw.status[k] = true
        end
        uw.access_time = Time.now
        return uw.save, "admin"
      else
        account = Account.find_or_create_by(:uid => result["uid"])
        account.access_token_weibo = result["access_token"]
        return account.save, account._id
      end
    else
      return false, result
    end
  end

  def self.get_one
    ac = where(:is_deleted => false).where(:on_crawl => false).asc(:last_use).first
    ac.last_use = Time.now.to_i
    ac.save
    ac
  end

  def self.get_api_one
    if ac = where(:is_deleted => false).where(:api_used.lt => 149).desc(:last_api_use).first
      ac.update_attribute :last_api_use, Time.now.to_i
    end
    ac
  end


  def get_proxy(change = false)
    self.proxy.update_attribute(:is_deleted, true) if change && self.proxy
    unless proxy && proxy.confirm
      if location.present?
        ::Proxy.location_at(location).confirm
        self.proxy = ::Proxy.get_one(location)
        if self.proxy.blank?
          self.proxy = ::Proxy.get_one 
          self.location = self.proxy.location
        end
      else
        self.proxy = ::Proxy.get_one
        self.location = self.proxy.location
      end

      save
    end
    proxy
  end

  def get_with_login(url, is_ajax = false)
    reload
    st = Time.now.to_i - last_use
    self.on_crawl = true; save
    ret = nil
    if st < SLEEP_TIME
      sleep(SLEEP_TIME - st)
    end
    begin
      self.last_use = Time.now
      page = @weibos_spider.get(url)
      if is_ajax
        #
      else
        page = is_relogin_page?(page)
        page = is_logined_page?(page, url)
        return false if is_block_page?(page)        
      end
      ret = page
    rescue SystemExit, Interrupt
      logger.fatal("SystemExit && Interrupt")
      exit!      
    rescue Exception => e
      logger.fatal(page.search("body").text)
      ret = false
    ensure
      self.on_crawl = false
      self.save
    end
    return ret
  end

  def is_block_page?(page)
    if page.uri.to_s.include?("http://weibo.com/sorry?userblock")
      self.destroy
      true
    else
      self.save
      false
    end
  end

  def is_relogin_page?(page)
    if page.uri.to_s.include?("login.sina.com.cn/sso/login.php?")
      wlr = page.search('script').to_s.match(/.replace\([\"\']([\w\W]*)[\"\']\)/)[1]
      page = @weibos_spider.get(wlr)
    elsif page.uri.to_s.include?("http://passport.weibo.com/visitor/visitor?a=enter")
      wlr = page.uri.to_s
      page = @weibos_spider.get(wlr)
    end
    save_cookies
    page
  end

  def is_logined_page?(page, url)
    if get_config(page, "islogin").to_s == '1'
      page
    else
      login
      page = @weibos_spider.get(url)
    end
  end

end