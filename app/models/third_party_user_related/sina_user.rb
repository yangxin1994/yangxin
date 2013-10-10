class SinaUser < ThirdPartyUser
    
  field :name, :type => String
  field :location, :type => String
  field :description, :type => String
  field :gender, :type => String #male will return: "m"
  field :profile_image_url, :type => String
  

  alias locale location
  alias get_user_info call_method  


  def self.get_access_token(code, redirect_uri)
    access_token_params = {
      "client_id" => OOPSDATA[Rails.env]["sina_app_key"],
      "client_secret" => OOPSDATA[Rails.env]["sina_app_secret"],
      "redirect_uri" => redirect_uri || OOPSDATA[Rails.env]["sina_redirect_uri"],
      "grant_type" => "authorization_code",
      "code" => code
    }
    retval = Tool.send_post_request("https://api.weibo.com/oauth2/access_token", access_token_params, true)
    response_data = JSON.parse(retval.body)
    Logger.new("log/development.log").info(response_data.to_s)
    
    return response_data
  end

  def self.save_tp_user(response_data)
    access_token = response_data["access_token"]
    website_id = response_data["uid"]
    
    # reject the same function field
    response_data.select!{|k,v| !k.to_s.include?("id") }
  
    #new or update sina_user
    sina_user = SinaUser.where(:website_id => website_id)[0]
    if sina_user.nil? then
      sina_user = SinaUser.new(:website => "sina", :website_id => website_id, :access_token => access_token)
      sina_user.save
      # this is not update instance, it would lead that other info should be seen in next login.
    else
      #sina_user.update_by_hash(response_data)
    end
    
    return sina_user
  end

  def call_method(http_method="get", opts = {:method => "users/show", :uid => self.user_id})
    @params={}
    @params["access_token"] = self.access_token
    method = opts[:method] || opts["method"]
    if http_method.downcase == "get"
      params_string = generate_params_string(opts)
      retval = Tool.send_get_request("https://api.weibo.com/2/#{method}.json#{params_string}", true) 
    else
      opts.merge!(@params).select!{|k,v| k.to_s != "method"}
      retval = Tool.send_post_request("https://api.weibo.com/2/#{method}.json", opts, true)
    end
    return JSON.parse(retval.body)
  end

  def update_user_info
    @select_attrs = %{name location gender description profile_image_url}
    super
  end
  


  def say_text(status)
    retval = call_method("post", {:method => "statuses/update", :status =>status}) 
    successful?(retval)
  end

  
  def repost_text(text_id, status=nil)
    retval = call_method("post", {:method => "statuses/repost", :id => text_id}) if status.nil?
    retval = call_method("post", {:method => "statuses/repost", :id => text_id, :status => status}) if !status.nil?
    successful?(retval)
  end


  def create_friendship(friend_id)
    retval = call_method("post", {:method => "friendships/create", :id => friend_id})
    successful?(retval)
  end


  def follow_topic(topic_name)
    retval = call_method("post", {:method => "trends/follow", :trend_name => topic_name})
    successful?(retval)
  end

  

  def logout
    retval = call_method("get", {:method => "account/end_session"}) 
    successful?(retval)
  end

end
