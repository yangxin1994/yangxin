class QihuUser < ThirdPartyUser

	field :name, :type => String
	field :sex, :type => String # male will return: 1
	field :headurl, :type => String

	alias gender sex

	def locale
		nil
	end

	#*description*: get access_token for other works
	#
	#*params*:
	#* code: code from third party respond.
	#
	#*retval*:
	#* response_data: it includes access_token, expires_in and user info
	def self.get_access_token(code, redirect_uri)
		access_token_params = {"client_id" => OOPSDATA[RailsEnv.get_rails_env]["qihu_app_key"],
			"client_secret" => OOPSDATA[RailsEnv.get_rails_env]["qihu_app_secret"],
			"redirect_uri" => redirect_uri,
			"grant_type" => "authorization_code",
			"code" => code}
		retval = Tool.send_post_request("https://openapi.360.cn/oauth2/access_token", access_token_params, true)
		response_data = JSON.parse(retval.body)
		return response_data
	end

	#*description*: receive params, then
	#
	# 1. new or update qihu_user
	#
	#*params*: 
	#* response_data: access_token, user_id and other
	#
	#*retval*:
	#* qihu_user: new or updated.
	def self.save_tp_user(response_data)
		
		access_token = response_data["access_token"]
		refresh_token = response_data["refresh_token"]
		expires_in = response_data["expires_in"]

		retval = Tool.send_get_request("https://openapi.360.cn/user/me?access_token=#{access_token}", true)

		response_data = JSON.parse(retval.body)

		website_id = response_data["id"]

		#new or update qihu_user
		qihu_user = QihuUser.where(:website_id => website_id)[0]
		if qihu_user.nil?
			qihu_user = QihuUser.new(:website => "qihu", :website_id => website_id, :access_token => access_token, 
			:refresh_token => refresh_token, :expires_in => expires_in)
			qihu_user.save
		else 
			#only update access_token, refresh_token, expires_in, remove other info which is un-useful.
			response_data = {}
			response_data["access_token"] = access_token 
			response_data["refresh_token"] = refresh_token
			response_data["expires_in"] = expires_in
			# update info 
			#qihu_user.update_by_hash(response_data)
		end
		
		#qihu_user.update_user_info
		
		return qihu_user
	end

end
