
class GoogleUser < ThirdPartyUser
  
  field :name, :type => String
  field :gender, :type => String
  field :locale, :type => String
  field :google_email, :type => String  
  
  #--
  #***************** class methods *************
  #++
  
  public
  
  #*description*: get access_token for other works
  #
  #*params*:
  #* code: code from third party respond.
  #
  #*retval*:
  #* response_data: it includes access_token, expires_in and other
  def self.get_access_token(code)
    #get access_token
    access_token_params = {"client_id" => OOPSDATA[RailsEnv.get_rails_env]["google_client_id"],
			"client_secret" => OOPSDATA[RailsEnv.get_rails_env]["google_client_secret"],
			"redirect_uri" => OOPSDATA[RailsEnv.get_rails_env]["google_redirect_uri"],
			"grant_type" => "authorization_code",
			"code" => code}
		retval = Tool.send_post_request("https://accounts.google.com/o/oauth2/token", access_token_params, true)
		response_data = JSON.parse(retval.body)
		Logger.new("log/development.log").info(response_data.to_s)
		#access_token = response_data["access_token"]
		return response_data
  end
  
  #*description*: receive params, then 
  #
  # 1. get user_id through access_token
  #
  # 2. new or update google_user
  #
  #*params*: 
  #* response_data: it includes access_token, expires_in and other
  #
  #*retval*:
  #* google_user: new or updated.
  def self.save_tp_user(response_data)
    access_token = response_data["access_token"]
  
    #get user_id
    retval = Tool.send_get_request("https://www.googleapis.com/oauth2/v1/userinfo?access_token=#{access_token}", true)
		response_data2 = JSON.parse(retval.body)
		user_id = response_data2["id"]
		response_data["google_email"] = response_data2["email"]
		
		# reject the same function field
		response_data.select!{|k,v| !k.to_s.include?("id") }
		response_data2.select!{|k,v| !k.to_s.include?("id") && k.to_s !="email" }
		
		# merge info
		response_data.merge!(response_data2)
		
		#new or update google_user
		google_user = GoogleUser.where(:user_id => user_id)[0]
		if google_user.nil? then
      google_user = GoogleUser.new(:website => "google", :user_id => user_id, :access_token => access_token)
      google_user.save
    else
      google_user = ThirdPartyUser.update_by_hash(google_user, response_data)
    end
    
    return google_user
  end
  
  #--
  # ************instance methods**********
  #++
  
  public
  
	#*description*: it can call any methods from third_party's API.
	#
	#*params*:
	#* opts: hash.
  def call_method(opts = {:method => "userinfo"})
    @params={}
    @params[:access_token] = self.access_token
    super(opts)
    Tool.send_get_request("https://www.googleapis.com/oauth2/v1/#{opts[:method]}#{@params_url}", true) 
  end
end
