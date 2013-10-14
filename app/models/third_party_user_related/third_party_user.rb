require 'encryption'
require 'error_enum'
require 'tool'
require 'uri'
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

  def self.get_access_token(opt)
    access_token_params = {
      "client_id" => OOPSDATA[Rails.env]["#{opt[:account]}_app_key"],
      "client_secret" => OOPSDATA[Rails.env]["#{opt[:account]}_app_secret"],
      "redirect_uri" => opt[:redirect_uri],
      "grant_type" => "authorization_code",
      "code" => opt[:param_obj][:code]
    }
    case opt[:account]
    when "sina"
      request_uri = "https://api.weibo.com/oauth2/access_token"
    when "renren"
      request_uri = "https://graph.renren.com/oauth/token"
    when "qq"
      request_uri = "https://graph.qq.com/oauth2.0/token"
      state = {"state" => Time.now.to_i}
      access_token_params.merge!(state)
    when "alipay"
      access_token_params = {
        "method" => 'alipay.system.oauth.token',
        "format" => 'json',
        "timestamp" => Time.now.strftime('%Y-%m-%d %H:%M:%S'),
        "app_id" => OOPSDATA[Rails.env]["#{opt[:account]}_app_key"],
        "version" => '1.0',
        "sign_type" => "RSA",
        "sign" => '',
        "platform" => 'top',
        "terminal_type" => 'web',
        "grant_type" => 'authorization_code',
        "code" => opt[:param_obj][:code]
      }

      request_uri = "https://openapi.alipay.com/gateway.do"
    when "tecent"
      request_uri = "https://open.t.qq.com/cgi-bin/oauth2/access_token"
      state = {"state" => Time.now.to_i}
      access_token_params.merge!(state)      
    when "qihu360" #TODO need ICP information
      request_uri = "https://openapi.360.cn/oauth2/access_token"
    end

    retval = Tool.send_post_request(request_uri, access_token_params, true)
    case opt[:account]
    when 'qq','tecent'
      access_token, expires_in, refresh_token = *(retval.body.split('&').map { |ele| ele.split('=')[1] })      
      response_data = {"access_token" => access_token, "expires_in" => expires_in,:refresh_token => refresh_token}
      response_data.merge!(opt[:param_obj])   
    else
      response_data = JSON.parse(retval.body)
    end 
    return response_data
  end

  def self.find_or_create_user(website, response_data,current_user)
    case website
    when "sina"
      tp_user = SinaUser.save_tp_user(response_data,current_user)
    when "renren"
      tp_user = RenrenUser.save_tp_user(response_data,current_user)
    when "qq"
      tp_user = QqUser.save_tp_user(response_data,current_user)
    when "tecent"
      tp_user = TecentUser.save_tp_user(response_data,current_user)
    when 'alipay'
      tp_user = AlipayUser.save_tp_user(response_data,current_user)
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


  def generate_params_string(opts = {})
    str = ''
    opts.each{|k,v| str += "&#{k}=#{v}"}
    str = str.sub!('&','?')
    return str     
  end

  
  def call_method(opt)
    if opt[:http_method].downcase == "get" 
      str =  generate_params_string(opt[:opts])
      retval = Tool.send_get_request(URI.encode("#{opt[:url]}#{opt[:action]}#{opt[:format]}#{str}"), true)      
    else
      retval = Tool.send_post_request("#{opt[:url]}#{opt[:action]}#{opt[:format]}", opt[:opts], true)
    end
    return JSON.parse(retval.body)
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
