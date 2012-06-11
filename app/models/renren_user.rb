
class RenrenUser < ThirdPartyUser
  
  field :name, :type => String
  field :sex, :type => String
  field :headurl, :type => String
  
  #--
  # ************* instance attribute's methods*****************
  #++
  
  #*attribute*: name
  def name
    self.user["name"]
  end
  
  #*attribute*: gender
  alias gender sex
  
  #*attribute*: locale
  def locale
    nil
  end
  
  #--
  #***************** class methods *************
  #++
  
  #*description*: get access_token for other works
  #
  #*params*:
  #* code: code from third party respond.
  #
  #*retval*:
  #* response_data: it includes access_token, expires_in and user info
  def self.get_access_token(code)
    access_token_params = {"client_id" => OOPSDATA[RailsEnv.get_rails_env]["renren_api_key"],
			"client_secret" => OOPSDATA[RailsEnv.get_rails_env]["renren_secret_key"],
			"redirect_uri" => OOPSDATA[RailsEnv.get_rails_env]["renren_redirect_uri"],
			"grant_type" => "authorization_code",
			"code" => code}
		retval = Tool.send_post_request("https://graph.renren.com/oauth/token", access_token_params, true)
		response_data = JSON.parse(retval.body)
		Logger.new("log/development.log").info(response_data.to_s)		
		return response_data
	end
	
  #*description*: receive params, then
  #
  # 1. new or update renren_user
  #
  #*params*: 
  #* response_data: access_token, user_id and other
  #
  #*retval*:
  #* renren_user: new or updated.
	def self.save_tp_user(response_data)
	  
		user_id = response_data["user"]["id"]
		access_token = response_data["access_token"]
		refresh_token = response_data["refresh_token"]
	  expires_in = response_data["expires_in"]
	 
	  #new or update renren_user
		renren_user = RenrenUser.where(:user_id => user_id)[0]
		if renren_user.nil? then
      renren_user = RenrenUser.new(:website => "renren", :user_id => user_id, :access_token => access_token, 
      :refresh_token => refresh_token, :expires_in => expires_in)
      renren_user.save
    else 
      #only update access_token, refresh_token, expires_in, remove other info which is un-useful.
      response_data = {}
      response_data["access_token"] = access_token 
      response_data["refresh_token"] = refresh_token
      response_data["expires_in"] = expires_in
      
      # update info 
      renren_user = ThirdPartyUser.update_by_hash(renren_user, response_data)
    end
    
    # first time get user base information.
    renren_user.update_user_info if renren_user.gender.nil?
    
    return renren_user
  rescue
    return nil
  end
  
  #--
  # ************instance methods**********
  #++
  
	#*description*: it can call any methods from third_party's API:
	#http://wiki.dev.renren.com/wiki/API
	#
	#*params*:
	#* http_method: get or post(default).
	#* opts: hash.
	#
	#*retval*:
	#
	# a hash data
  def call_method(http_url="post", opts = {:method => "users.getInfo"})
    @params = {}
    @params[:call_id] = Time.now.to_i
    @params[:format] = 'json'
    @params[:v] = '1.0'
    @params[:access_token] = self.access_token
    
    if http_url.downcase == "post" then
    #Logger.new("log/development.log").info("get api url: http://api.renren.com/restserver.do, #{update_params(opts)}")
      return ActiveSupport::JSON.decode(Tool.send_post_request('http://api.renren.com/restserver.do', update_params(opts)).body)
    else
      nil
    end
  end
  
	#*description*: get user base info, it involves call_method.
	#
	#*params*: none
	#
	#*retval*:
	#
	# a hash data
  def get_user_info
    call_method()[0]
  end
  
  #*description*: add share of a link information.
  #API: http://wiki.dev.renren.com/wiki/Share.share
	#
	#*params*: 
	#* url: the place which you want to share
	#
	#*retval*:
	#
	# say successfully or not.
  def add_share(url)
    retval = call_method("post", {:method => "share.share", :type => 6, :url => url}) 
    
    successful?(retval)   
  end
  
  #*description*: add share of a link information.
  #
  #Note: your like the url page must has "<meta property="xn:app_id" content="your appid" />".
  #Otherwise, it would be lose.Maybe, you should see 
  # API: http://wiki.dev.renren.com/wiki/Like.like
	#
	#*params*: 
	#* url: the place which you like
	#
	#*retval*:
	#
	# say successfully or not.
  def add_like(url)
    retval = call_method("post", {:method => "like.like", :url => url}) 
    
    successful?(retval)  
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
  
  #*description*: reget access_token from refresh_token for other works
  #
  #*params*:
  #* code: code from third party respond.
  #
  #*retval*:
  #* response_data: it includes access_token, expires_in ,refresh_token and others
  def reget_access_token    
    access_token_params = {"client_id" => OOPSDATA[RailsEnv.get_rails_env]["renren_api_key"],
			"client_secret" => OOPSDATA[RailsEnv.get_rails_env]["renren_secret_key"],
			"redirect_uri" => OOPSDATA[RailsEnv.get_rails_env]["renren_redirect_uri"],
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
  
  #*description*: the renren params must be diff computed.
  #
  #*params*
  #* opts: hash for params.
  def update_params(opts)
    params = @params.merge(opts){|key, first, second| second}
    params[:sig] = Digest::MD5.hexdigest(params.map{|k,v| "#{k}=#{v}"}.sort.join + OOPSDATA[RailsEnv.get_rails_env]["renren_secret_key"])
    params
  end
  
end
