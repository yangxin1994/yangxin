class RenrenUser < ThirdPartyUser

  field :name, :type => String
  field :sex, :type => String # male will return: 1
  field :headurl, :type => String

  alias gender sex

  def locale
      nil
  end

  def self.get_access_token(code, redirect_uri)
    access_token_params = {
      "client_id" => OOPSDATA[Rails.env]["renren_api_key"],
      "client_secret" => OOPSDATA[Rails.env]["renren_secret_key"],
      "redirect_uri" => redirect_uri || OOPSDATA[Rails.env]["renren_redirect_uri"],
      "grant_type" => "authorization_code",
      "code" => code
    }
    retval = Tool.send_post_request("https://graph.renren.com/oauth/token", access_token_params, true)
    response_data = JSON.parse(retval.body)
    return response_data
  end

  def self.save_tp_user(response_data)

    website_id = response_data["user"]["id"]
    access_token = response_data["access_token"]
    refresh_token = response_data["refresh_token"]
    expires_in = response_data["expires_in"]
   
    #new or update renren_user
    renren_user = RenrenUser.where(:website_id => website_id)[0]
    if renren_user.nil?
      renren_user = RenrenUser.new(:website => "renren", :website_id => website_id, :access_token => access_token, 
      :refresh_token => refresh_token, :expires_in => expires_in)
      renren_user.save
    else 
      #only update access_token, refresh_token, expires_in, remove other info which is un-useful.
      response_data = {}
      response_data["access_token"] = access_token 
      response_data["refresh_token"] = refresh_token
      response_data["expires_in"] = expires_in
      # update info 
      #renren_user.update_by_hash(response_data)
    end
    return renren_user
  end

  def call_method(http_method="post", opts = {:method => "users.getInfo"})
    @params = {}
    @params[:call_id] = Time.now.to_i
    @params[:format] = 'json'
    @params[:v] = '1.0'
    @params[:access_token] = self.access_token
    
    if http_method.downcase == "post" then
      retval = JSON.parse(Tool.send_post_request('http://api.renren.com/restserver.do', update_params(opts)).body)
    else
      return {}
    end
  end

  def get_user_info
    call_method()[0]
  end

  def add_share(url, type=6)
    retval = call_method("post", {:method => "share.share", :type => type, :url => url}) 
    successful?(retval)   
  end

  def add_like(url)
    retval = call_method("post", {:method => "like.like", :url => url}) 
    successful?(retval)  
  end

  def update_user_info
    @select_attrs = %{name sex headurl}
    super
  end

  def reget_access_token    
    access_token_params = {"client_id" => OOPSDATA[Rails.env]["renren_api_key"],
      "client_secret" => OOPSDATA[Rails.env]["renren_secret_key"],
      "redirect_uri" => OOPSDATA[Rails.env]["renren_redirect_uri"],
      "grant_type" => "refresh_token",
      "refresh_token" => self.refresh_token}
    retval = Tool.send_post_request("https://graph.renren.com/oauth/token", access_token_params, true)
    response_data = JSON.parse(retval.body)
    
    access_token = response_data["access_token"]
    refresh_token = response_data["refresh_token"]

    self.update_access_token(access_token)
    self.update_refresh_token(refresh_token)
    
    return response_data
  end  

  private

  def update_params(opts)
    params = @params.merge(opts){|key, first, second| second}
    params[:sig] = Digest::MD5.hexdigest(params.map{|k,v| "#{k}=#{v}"}.sort.join + OOPSDATA[Rails.env]["renren_secret_key"])
    params
  end

end
