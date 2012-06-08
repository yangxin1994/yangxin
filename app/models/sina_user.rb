
class SinaUser < ThirdPartyUser
  
  field :name, :type => String
  field :location, :type => String
  field :description, :type => String
  field :gender, :type => String
  field :profile_image_url, :type => String
  
  #--
  # ************* instance attribute's methods*****************
  #++
  
  #*attribute*: name
  # the same getter with db
  
  #*attribute*: gender
  # the same getter with db
  
  #*attribute*: locale
  alias locale location
  
  #--
  #***************** class methods *************
  #++
  
  #*description*: get access_token for other works
  #
  #*params*:
  #* code: code from third party respond.
  #
  #*retval*:
  #* response_data: it includes access_token, expires_in and user id
  def self.get_access_token(code)
    access_token_params = {"client_id" => OOPSDATA[RailsEnv.get_rails_env]["sina_app_key"],
			"client_secret" => OOPSDATA[RailsEnv.get_rails_env]["sina_app_secret"],
			"redirect_uri" => OOPSDATA[RailsEnv.get_rails_env]["sina_redirect_uri"],
			"grant_type" => "authorization_code",
			"code" => code}
		retval = Tool.send_post_request("https://api.weibo.com/oauth2/access_token", access_token_params, true)
		response_data = JSON.parse(retval.body)
		Logger.new("log/development.log").info(response_data.to_s)
		#access_token = response_data["access_token"]
		#user_id = response_data["uid"]
		
		return response_data
	end
	
  # receive params, then 
  #
  # 1. new or update sina_user
  #
  #*params*: 
  #
  #* response_data: access_token, user_id and other
  #
  #*retval*:
  #
  #* sina_user: new or updated.
	def self.save_tp_user(response_data)
	  access_token = response_data["access_token"]
		user_id = response_data["uid"]
		
		# reject the same function field
		response_data.select!{|k,v| !k.to_s.include?("id") }
	
	  #new or update sina_user
		sina_user = SinaUser.where(:user_id => user_id)[0]
		if sina_user.nil? then
      sina_user = SinaUser.new(:website => "sina", :user_id => user_id, :access_token => access_token)
      sina_user.save
      # this is not update instance, it would lead that other info should be seen in next login.
    else
      sina_user = ThirdPartyUser.update_by_hash(sina_user, response_data)
    end
    
    if sina_user.gender.nil? then
      #first time, get user base info 
      sina_user = sina_user.update_user_info
    end
    
    return sina_user
  end
  
  #--
  # ************instance methods**********
  #++
  
	#*description*: it can call any methods from third_party's API:
	#http://open.weibo.com/wiki/API%E6%96%87%E6%A1%A3_V2
	#
	#*params*:
	#* opts: hash.
  def call_method(url_method="GET", opts = {:method => "users/show", :uid => self.user_id})
    
    if url_method.downcase == "get" then
      @params={}
      @params["access_token"] = self.access_token
      super(opts)
      retval = Tool.send_get_request("https://api.weibo.com/2/#{opts[:method]}.json#{@params_url}", true) 
    else
      opts["access_token"] = self.access_token
      retval = Tool.send_post_request("https://api.weibo.com/2/#{opts[:method]}.json", opts.select!{|k,v| k.to_s != "method"}, true)
    end
    return JSON.parse(retval.body)
  end
  
  alias get_user_info call_method
  
	#*description*: update user base info, it involves get_user_info.
	#
	#*params*: none
	#
	#*retval*:
	#* instance: a updated renren user.
  def update_user_info
    response_data = get_user_info
      
    #select attribute
    response_data.select!{|k,v| %{name location gender description profile_image_url}.split.include?(k.to_s) }
    
    #update
    return ThirdPartyUser.update_by_hash(self, response_data)
  end
  
  #*description*: say weibo text
	#
	#*params*: 
	#* status: what is you want to say.
	#
	#*retval*:
	#
	# say successfully or not.
  def say_text(status)
    retval = call_method("post", {:method => "statuses/update", :status =>text_content})
    
    successful?(retval)
  end
  
  #*description*: repost a weibo without message
	#
	#*params*: 
	#* text_id: the weibo's id which is you want to repost.
	#
	#*retval*:
	#
	# say successfully or not.
  def repost_text(text_id)
    retval = call_method("post", {:method => "statuses/repost", :id => text_id})
    
    successful?(retval)
  end

  #*description*: repost a weibo with message
	#
	#*params*: 
	#* text_id: the weibo's id which is you want to repost.
	#* status: what is you want to say.
	#
	#*retval*:
	#
	# say successfully or not.
  def repost_text_with_message(text_id, status)
    retval = call_method("post", {:method => "statuses/repost", :id => text_id, :status => status})
    
    successful?(retval)
  end

  #*description*: follow someone.
	#
	#*params*: 
	#* friend_id: the friend's id.
	#
	#*retval*:
	#
	# say successfully or not.
  def create_friendship(friend_id)
    retval = call_method("post", {:method => "friendships/create", :id => friend_id})
    
    successful?(retval)
  end
  
  #*description*: logout action
	#
	#*params*: none
	#
	#*retval*:
	#
	# say successfully or not.
  def logout
    retval = call_method("get", {:method => "account/end_session"})
    
    successful?(retval)
  end

end
