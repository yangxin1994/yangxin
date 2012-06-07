
class QqUser < ThirdPartyUser
  
  field :nickname, :type => String
  field :gender, :type => String
  field :figureurl, :type => String
  
  #--
  #***************** class methods *************
  #++
  
  #get access_token for other works
  #
  #*params*:
  #
  #*code: code from third party respond.
  #
  #*retval*:
  #
  #* response_data: it includes access_token, expires_in
  def self.get_access_token(code)
    access_token_params = {"client_id" => OOPSDATA[RailsEnv.get_rails_env]["qq_app_id"],
			"client_secret" => OOPSDATA[RailsEnv.get_rails_env]["qq_app_key"],
			"redirect_uri" => OOPSDATA[RailsEnv.get_rails_env]["qq_redirect_uri"],
			"grant_type" => "authorization_code",
			"state" => Time.now.to_i,
			"code" => code}
		retval = Tool.send_post_request("https://graph.qq.com/oauth2.0/token", access_token_params, true)
		access_token, expires_in = *(retval.body.split('&').map { |ele| ele.split('=')[1] })
		Logger.new("log/development.log").info(retval.body.to_s)
		
		response_data = {"access_token" => access_token, "expires_in" => expires_in}		
		return response_data
	end
	
  # receive params, then 
  #
  # 1. get user_id through access_token
  #
  # 2. new or update qq_user
  #
  #*params*: 
  #
  #* response_data: access_token, expires_in
  #
  #*retval*:
  #
  #*qq_user: new or updated.
	def self.save_tp_user(response_data)
	  access_token = response_data["access_token"]
	  expires_in = response_data["expires_in"]
	  
    #get user_id through access_token
		retval = Tool.send_get_request("https://graph.qq.com/oauth2.0/me?access_token=#{access_token}", true)
		Logger.new("log/development.log").info(retval.to_s)
		response_data2 = JSON.parse(retval.body.split(' ')[1])
		user_id = response_data2["openid"]
		
		# reject the same function field
		response_data.select!{|k,v| !k.to_s.include?("id") }
		response_data2.select!{|k,v| !k.to_s.include?("id") }
		
		# merge info
		response_data.merge!(response_data2)
		
		#new or update qq_user
		qq_user = QqUser.where(:user_id => user_id)[0]
		if qq_user.nil? then
      qq_user = QqUser.new(:website => "qq", :user_id => user_id, :access_token => access_token)
      qq_user.save
    else
      qq_user = ThirdPartyUser.update_by_hash(qq_user, response_data)
    end
    
    return qq_user
  end
  
  #--
  # ************instance methods**********
  #++
  
	#*description*: it can call any methods from third_party's API:
	#http://wiki.opensns.qq.com/wiki/%E3%80%90QQ%E7%99%BB%E5%BD%95%E3%80%91API%E6%96%87%E6%A1%A3
	#
	#*params*:
	#
	#*opts: hash.
  def call_method(opts = {:method => "get_user_info"})
    @params={}
    @params[:access_token] = self.access_token
    @params[:oauth_consumer_key] = OOPSDATA[RailsEnv.get_rails_env]["qq_app_id"]
    @params[:openid] = self.user_id
    super(opts)
    retval = Tool.send_get_request("https://graph.qq.com/user/#{opts[:method]}#{@params_url}", true)
    return JSON.parse(retval.body)
  end
  
end
