class GoogleUser < ThirdPartyUser

	field :name, :type => String
	field :gender, :type => String #male will return: "male"
	field :locale, :type => String
	field :google_email, :type => String  

	#--
	# ************* instance attribute's methods*****************
	#++

	#*attribute*: name
	# the same getter with db

	#*attribute*: gender
	# the same getter with db

	#*attribute*: locale
	# the same getter with db 

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
		return nil if !response_data2.select{|k,v| k.to_s.include?("error")}.empty?
		
		user_id = response_data2["id"]
		
		# reject the same function field
		response_data["google_email"] = response_data2["email"]
		response_data2.select!{|k,v| !k.to_s.include?("id") && k.to_s !="email" }
		
		# merge info
		response_data.merge!(response_data2).select!{|k,v| !k.to_s.include?("id") }
		#select info 
		attrs = %{access_token refresh_token expires_in name gender locale google_email}
		response_data.select!{|k,v| attrs.split.include?(k.to_s)}
		
		#new or update google_user
		google_user = GoogleUser.where(:user_id => user_id)[0]
		if google_user.nil? then
			response_data.merge!({"website"=>"google", "user_id" => user_id })
			
			google_user = GoogleUser.new(response_data)
			google_user.save
		else
			# it contains access_token ...
			google_user.update_by_hash(response_data)
		end
		
		return google_user
	rescue => ex 
		return nil
	end

	#--
	# ************instance methods**********
	#++

	public

	#*description*: it can call any methods from third_party's API.
	#
	#*params*:
	#* http_method: get or post.
	#* opts: hash.
	def call_method(http_method="get", opts = {:method => "userinfo"})
		@params={}
		@params[:access_token] = self.access_token
		method = opts[:method] || opts["method"]
		
		if http_method.downcase == "get"  then
			params_string = generate_params_string(opts)
			retval = Tool.send_get_request("https://www.googleapis.com/oauth2/v1/#{method}#{params_string}", true) 
		else
			opts.merge!(@params).select!{|k,v| k.to_s != "method"}
			retval = Tool.send_post_request("https://www.googleapis.com/oauth2/v1/#{method}", opts, true)
		end
		return JSON.parse(retval.body)
	end

	alias get_user_info call_method

	#*description*: update user base info, it involves get_user_info.
	#
	#*params*: none
	#
	#*retval*:
	#* instance: a updated google user.
	def update_user_info
		#Logger.new("log/development.log").info("update_user_info. ")
		@select_attrs = %{name gender locale google_email}
		super
	end

end
