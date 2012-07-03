
class QihuUser < ThirdPartyUser
  
  #***************** class methods *************
  
  def self.token(code)
    access_token_params = {"client_id" => OOPSDATA[RailsEnv.get_rails_env]["qihu_app_key"],
			"client_secret" => OOPSDATA[RailsEnv.get_rails_env]["qihu_app_secret"],
			"redirect_uri" => OOPSDATA[RailsEnv.get_rails_env]["qihu_redirect_uri"],
			"grant_type" => "authorization_code",
			"code" => code
      }
		retval = Tool.send_post_request("https://openapi.360.cn/oauth2/access_token", access_token_params, true)
		response_data = JSON.parse(retval.body)
		Logger.new("log/development.log").info(response_data.to_s)
		access_token = response_data["access_token"]
		retval = Tool.send_get_request("https://openapi.360.cn/user/me.json?access_token=#{access_token}", true)
		response_data = JSON.parse(retval.body)
		user_id = response_data["id"]
		
		qihu_user = QihuUser.where(:user_id => user_id)[0]
		if qihu_user.nil? then
      qihu_user = QihuUser.new(:website => "qihu", :user_id => user_id, :access_token => access_token)
    else
      hash = {}
      hash[:access_token] = access_token
      qihu_user.update_by_hash(hash)
    end
    
    return [ErrorEnum::SAVE_FAILED, nil] if qihu_user.nil?
    return [ErrorEnum::THIRD_PARTY_USER_NOT_BIND, qihu_user] if qihu_user.email.nil? || qihu_user.email =""
    user = User.find_by_email(qihu_user.email)
    if !user.nil? then
      return [ErrorEnum::EMAIL_NOT_ACTIVATED, qihu_user] if user.status == 0
    end
    return [true, qihu_user]
  rescue => e
    puts "#{e.class}: #{e.message}"
    raise e
  end
  
  # ************instance methods**********
  
  def call_method(opts = {})
   
  end
  
end
