require 'net'
class SohuUser < ThirdPartyUser

  field :name, :type => String

  #*description*: get access_token for other works
  #
  #*params*:
  #* code: code from third party respond.
  #
  #*retval*:
  #* response_data: it includes access_token, expires_in and user info
  def self.get_access_token(code, redirect_uri)
    access_token_params = {
      "client_id" => OOPSDATA[Rails.env]["sohu_app_key"],
      "client_secret" => OOPSDATA[Rails.env]["sohu_app_secret"],
      "redirect_uri" => redirect_uri,
      "grant_type" => "authorization_code",
      "code" => code
    }
    retval = Tool.send_post_request("https://api.sohu.com/oauth2/token", access_token_params, true)
    response_data = JSON.parse(retval.body)
    return response_data
  end

  #*description*: receive params, then
  #
  # 1. new or update sohu_user
  #
  #*params*: 
  #* response_data: access_token, user_id and other
  #
  #*retval*:
  #* sohu_user: new or updated.
  def self.save_tp_user(response_data)
      
    access_token = response_data["access_token"]
    refresh_token = response_data["refresh_token"]
    expires_in = response_data["expires_in"]
    website_id = response_data["open_id"]

    #new or update sohu_user
    sohu_user = SohuUser.where(:website_id => website_id)[0]
    if sohu_user.nil?
      sohu_user = SohuUser.new(:website => "sohu", :website_id => website_id, :access_token => access_token, 
      :refresh_token => refresh_token, :expires_in => expires_in)
      sohu_user.save
    else 
      #only update access_token, refresh_token, expires_in, remove other info which is un-useful.
      response_data = {}
      response_data["access_token"] = access_token 
      response_data["refresh_token"] = refresh_token
      response_data["expires_in"] = expires_in
    end
    
    return sohu_user
  end

  #*description*: get user base info, it involves call_method.
  #
  #*params*: none
  #
  #*retval*:
  #
  # a hash data
  def get_user_info
    # if not a array, it should be error for user login.
    call_method()[0]
  end

  #*description*: get user base info, it involves get_user_info.
  #
  #*params*: none
  #
  #*retval*:
  #* instance: a updated renren user.
  def update_user_info
    @select_attrs = %{name sex headurl}
    super
  end

end
