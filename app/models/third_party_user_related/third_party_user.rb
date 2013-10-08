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
        response_data = SinaUser.get_access_token(code, redirect_uri)
    when "renren"
        response_data = RenrenUser.get_access_token(code, redirect_uri)
    when "qq"
        response_data = QqUser.get_access_token(code, redirect_uri)
    when "google"
        response_data = GoogleUser.get_access_token(code, redirect_uri)
    when "kaixin001"
        response_data = KaixinUser.get_access_token(code, redirect_uri)
    when "douban"
        response_data = DoubanUser.get_access_token(code, redirect_uri)
    when "baidu"
        response_data = BaiduUser.get_access_token(code, redirect_uri)
    when "sohu"
        response_data = SohuUser.get_access_token(code, redirect_uri)
    when "qihu360"
        response_data = QihuUser.get_access_token(code, redirect_uri)
    else
        response_data = {}
    end

    return response_data
  end


  # def self.get_access_token(website, code, redirect_uri)
  #   case website
  #   when "sina"
  #       auth_url = "https://api.weibo.com/oauth2/access_token"
  #   when "renren"
  #       auth_url = "https://graph.renren.com/oauth/token"
  #   when "qq"
  #       auth_url = "https://graph.qq.com/oauth2.0/token"
  #   when "google"
  #       auth_url = "https://accounts.google.com/o/oauth2/token"
  #   when "kaixin001"
  #       auth_url = "https://api.kaixin001.com/oauth2/access_token"
  #   when "douban"
  #       auth_url = "https://www.douban.com/service/auth2/token"
  #   when "baidu"
  #       auth_url = "https://openapi.baidu.com/oauth/2.0/token"
  #   when "sohu"
  #       auth_url = "https://api.sohu.com/oauth2/token"
  #   when "qihu360"
  #       auth_url = "https://openapi.360.cn/oauth2/access_token"
  #   end

  #   access_token_params = {
  #     "client_id" => OOPSDATA[Rails.env]["#{website}_api_key"],
  #     "client_secret" => OOPSDATA[Rails.env]["#{website}_api_secret"],
  #     "redirect_uri" => redirect_uri,
  #     "grant_type" => "authorization_code",
  #     "code" => code
  #   }

  #   if auth_url.present?
  #     retval = Tool.send_post_request(auth_url, access_token_params, true)  
  #     response_data = JSON.parse(retval.body)
  #   else
  #     response_data = {}
  #   end
  #   return response_data
    
  # end


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
  
  #*description*: update specifi ThirdPartyUser sub class instance 
  #by hash which has update attributes.
  #
  #*params*:
  #* hash
  #
  #*retval*:
  #* self: like GoogleUser's instance, SinaUser's instance ...
  def update_by_hash(hash)
    attrs = self.attributes
    attrs.merge!(hash)
    self.class.collection.find_and_modify(:query => {_id: self.id}, :update => attrs, :new => true)
    return self
  end
  
  #*description*: update user base info, it involves get_user_info.
  #
  #*params*: none
  #
  #*retval*:
  #* instance: a updated tp_user instance
  def update_user_info
    response_data = get_user_info
    #select attribute
    response_data.select!{|k,v| @select_attrs.split.include?(k.to_s) }
    #update
    return self.update_by_hash(response_data)
  end
  
  # description: generate parameters string used by http get request
  #
  #*params*:
  #
  #*opts: hash.
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
  
  #*description*: judge of a text's action.
  #
  #*params*: 
  #* hash: a hash which some website response.
  #
  #*retval*:
  #* bool: true or false
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
