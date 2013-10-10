require 'net'
class BaiduUser < ThirdPartyUser

  field :name, :type => String

  def self.get_access_token(code, redirect_uri)
    access_token_params = {
      "client_id" => OOPSDATA[Rails.env]["baidu_api_key"],
      "client_secret" => OOPSDATA[Rails.env]["baidu_api_secret"],
      "redirect_uri" => redirect_uri,
      "grant_type" => "authorization_code",
      "code" => code
    }
    retval = Tool.send_post_request("https://openapi.baidu.com/oauth/2.0/token", access_token_params, true)
    response_data = JSON.parse(retval.body)
    return response_data
  end


  def self.save_tp_user(response_data)
      
    access_token = response_data["access_token"]
    refresh_token = response_data["refresh_token"]
    expires_in = response_data["expires_in"]

    retval = Tool.send_get_request("https://openapi.baidu.com/rest/2.0/passport/users/getInfo?access_token=#{access_token}", true)

    response_data = JSON.parse(retval.body)

    website_id = response_data["userid"]

    #new or update baidu_user
    baidu_user = BaiduUser.where(:website_id => website_id)[0]
    if baidu_user.nil?
      baidu_user = BaiduUser.new(:website => "baidu", :website_id => website_id, :access_token => access_token, 
      :refresh_token => refresh_token, :expires_in => expires_in)
      baidu_user.save
    else 
      #only update access_token, refresh_token, expires_in, remove other info which is un-useful.
      response_data = {}
      response_data["access_token"] = access_token 
      response_data["refresh_token"] = refresh_token
      response_data["expires_in"] = expires_in
      # update info 
      #baidu_user.update_by_hash(response_data)
    end

    return baidu_user
  end

  def get_user_info
    # if not a array, it should be error for user login.
    call_method()[0]
  end

  def update_user_info
    @select_attrs = %{name sex headurl}
    super
  end
end
