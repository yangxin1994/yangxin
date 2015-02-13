# encoding: utf-8
require 'net/http'
require 'net/https'
require './lib/model/weibo_artist'

class HttpHelper
  def self.post(uri, data={})
    uri = URI.parse(uri)
    https = Net::HTTP.new(uri.host,uri.port)
    https.use_ssl = true
    if RbConfig::CONFIG["host_os"] =~ /min/
      https.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    req = Net::HTTP::Post.new(uri.path)
    req.set_form_data data
    https.request(req).body
  end

  def self.post_j(uri, data={})
    JSON.parse(post(uri, data))
  end

  def self.get(uri, data={})
    _uir = uri
    url_params = ''
    unless data.empty?
      url_params = "?"
      data.each do |key, value|
        url_params += "#{key}=#{value}&"
      end
      url_params[-1] = ''
    end
    uri = URI.parse(URI.escape(uri + url_params))
    # uri = URI.parse(uri + url_params)
    https = Net::HTTP.new(uri.host,uri.port)
    if _uir.match(/^https:\/\//)
      https.use_ssl = true
      if RbConfig::CONFIG["host_os"] =~ /min/
        https.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
    end
    req = Net::HTTP::Get.new(uri.to_s)
    https.request(req).body
  end


  def self.get_j(uri, data={})
    JSON.parse(get(uri, data))
  end

  def self.get_q(uri, data={})
    p "开始请求:解析地址"
    result = Rack::Utils.parse_nested_query(get(uri, data))
    result
  end
end

module Spider::WeiboApis

  # FLOWY_URL             = 'http://flowy.oopsdata.com'
  FLOWY_URL             = 'localhost'
  # oopsdata
  WEIBO_CLIENT_ID       = "2855748750"
  WEIBO_CLIENT_SECRET   = "3c07d73e3d5f6516c77cbff26ebfba61"
  # WEIBO_CALLBACK_URL  = "http://flowy.oopsdata.net/weibo"
  # WEIBO_CALLBACK_URL    = "http://flowy.oopsdata.com/weibo"
  WEIBO_CALLBACK_URL    = "http://127.0.0.1/weibo"
  WEIBO_ACCESS_URL      = ""

  def params(options)
    @account.api_used += 1
    {
      :access_token => @account.access_token,
    }.merge!(options)
  end

  def show(uid, screen_name)
    result = {"error" => "nil_error"}
    unless wum = WeiboUser.where(:wid => uid).first
      result = HttpHelper.get_j 'https://api.weibo.com/2/users/show.json', params( 
        :screen_name => screen_name
      )
      if result["error"].blank?
        wum = WeiboUser.find_or_create_by(:wid => result["id"])
        wum.update_attributes(result)
      else
        return result
      end      
    end
    @movie.weibo_users << wum 
    wum.save
    wum
  end

  def in_common(weibo_user)
    result = HttpHelper.get_j 'https://api.weibo.com/2/friendships/friends/in_common.json', params( 
      :uid => @account.uid,
      :suid => weibo_user.wid
    )
    if result["error"].blank?
      watica = @movie.weibo_artists.map(&:wid) & result["users"].map { |e| e['id'] }
      watica.each do |wat|
        weibo_artist = WeiboArtist.find_by("wid" => wat)
        weibo_user.weibo_artists << weibo_artist
        weibo_artist = weibo_artist
        @movie.for_artists[weibo_artist.wid] = @movie.for_artists[weibo_artist.wid].to_i + 1
      end
      @movie.for_artists["count"] = @movie.for_artists["count"] + 1
      weibo_user.save
      watica
    end
  end

  def initialize
    super
    @account = Account.get_api_one
  end

  def crawl_weibo_user
    return false unless @movie
    return false unless @account
    @movie.weibos.incrawl.each do |weibo|
      @account = Account.get_api_one if @account.api_used >=150
      break unless @account
      weibo_user = show(weibo.uid, weibo.user_name)
      binding.pry if weibo_user["error"]
      # 如果错误为10023 换账号
      @account.api_used = 150 if weibo_user["error_code"] == 10023 || weibo_user["error_code"] == 21321
      @account.save
      next if weibo_user["error"]
      weibo.update_attribute 'is_crawled', true if in_common(weibo_user)
    end
    binding.pry
    @movie.save
  end
  
end