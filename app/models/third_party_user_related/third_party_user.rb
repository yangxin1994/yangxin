require 'encryption'
require 'error_enum'
require 'tool'
class ThirdPartyUser

  include Mongoid::Document
  include FindTool

  # website can be "renren", "sina", "qq", "google", "qihu"
  field :website, :type => String
  field :website_id, :type => String
  field :access_token, :type => String
  field :refresh_token, :type => String
  field :expires_in, :type => String
  field :scope, :type => String
  field :share, :type => Boolean, default: false

  belongs_to :user

  index({ _type: 1, website_id: 1 }, { background: true } )

  index({user_id: 1, website_id: 1 }, { background: true } )

  public

  def self.get_access_token(website, code, redirect_uri)
    case website
    when "sina"
      request_uri = "https://api.weibo.com/oauth2/access_token"
    when "renren"
      request_uri = "https://graph.renren.com/oauth/token"
    when "qq"
      request_uri = "https://graph.qq.com/oauth2.0/token"
    when "qihu360"
      request_uri = "https://api.weibo.com/oauth2/access_token"
    when "alipay"
      request_uri = "https://api.weibo.com/oauth2/access_token"
    when "tecent"
      request_uri = "https://api.weibo.com/oauth2/access_token"
    # when "google"
    #   request_uri = "https://api.weibo.com/oauth2/access_token"
    # when "kaixin001"
    #   request_uri = "https://api.weibo.com/oauth2/access_token"
    # when "douban"
    #   request_uri = "https://api.weibo.com/oauth2/access_token"
    # when "baidu"
    #   request_uri = "https://api.weibo.com/oauth2/access_token"
    # when "sohu"
    #   request_uri = "https://api.weibo.com/oauth2/access_token"
    end

    access_token_params = {
      "client_id" => OOPSDATA[Rails.env]["#{website}_app_key"],
      "client_secret" => OOPSDATA[Rails.env]["#{website}_app_secret"],
      "redirect_uri" => redirect_uri || OOPSDATA[Rails.env]["#{website}_redirect_uri"],
      "grant_type" => "authorization_code",
      "code" => code
    }
---------------------
    access_token_params = {
      "client_id" => OOPSDATA[Rails.env]["qq_app_id"],
      "client_secret" => OOPSDATA[Rails.env]["qq_app_key"],
      "redirect_uri" => redirect_uri || OOPSDATA[Rails.env]["qq_redirect_uri"],
      "grant_type" => "authorization_code",
      "state" => Time.now.to_i,
      "code" => code
    }
    retval = Tool.send_post_request("https://graph.qq.com/oauth2.0/token", access_token_params, true)
    access_token, expires_in = *(retval.body.split('&').map { |ele| ele.split('=')[1] })
    
    response_data = {"access_token" => access_token, "expires_in" => expires_in}        
    return response_data
------------------------
    retval = Tool.send_post_request(request_uri, access_token_params, true)
    response_data = JSON.parse(retval.body)
    return response_data
  end

  def self.find_or_create_user(website, response_data)
    case website
    when "sina"
      tp_user = SinaUser.save_tp_user(response_data)
    when "renren"
      tp_user = RenrenUser.save_tp_user(response_data)
    when "qq"
      tp_user = QqUser.save_tp_user(response_data)
    when "google"
      tp_user = GoogleUser.save_tp_user(response_data)
    when "kaixin001"
      tp_user = KaixinUser.save_tp_user(response_data)
    when "douban"
      tp_user = DoubanUser.save_tp_user(response_data)
    when "baidu"
      tp_user = BaiduUser.save_tp_user(response_data)
    when "sohu"
      tp_user = SohuUser.save_tp_user(response_data)
    when "qihu360"
      tp_user = QihuUser.save_tp_user(response_data)
    else
      return ErrorEnum::WRONG_THIRD_PARTY_WEBSITE
    end
    return tp_user
  end

  def is_bound(user = nil)
    return false if user.nil?
    return self.oopsdata_user_id == user.id
  end

  def bind(user)
    user.third_party_users << self
  end
  
  def update_by_hash(hash)
    attrs = self.attributes
    attrs.merge!(hash)
    self.class.collection.find_and_modify(:query => {_id: self.id}, :update => attrs, :new => true)
    return self
  end

  
  def update_user_info
    response_data = get_user_info
    #select attribute
    response_data.select!{|k,v| @select_attrs.split.include?(k.to_s) }
    #update
    return self.update_by_hash(response_data)
  end

  
  def generate_params_string(opts = {})
    params_string = ""
    params.merge(opts.select {|k,v| k.to_s!="method"}).each{|k, v| @params_string +="&#{k}=#{v}"}
    params_string.sub!("&","?")
    return params_string
  end
  
  #update instance's access_token and save
  def update_access_token(access_token)
    self.access_token = access_token
    return self.save
  end
  
  #update instance's refresh_token and save
  def update_refresh_token(refresh_token)
    self.refresh_token = refresh_token
    return self.save
  end
  
  # update instance's scope and save
  def update_scope(scope)
    self.scope = scope
    return self.save
  end
  
  def successful?(hash)
    if hash.select{|k,v| k.to_s.include?("error")}.empty? then
      Logger.new("log/development.log").info("true: ")
      return true
    else
      Logger.new("log/development.log").info("false: ")
      return false
    end   
  end
end
