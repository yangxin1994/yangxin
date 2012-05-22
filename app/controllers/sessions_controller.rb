# encoding: utf-8
require 'encryption'
require 'error_enum'
require 'tool'
class SessionsController < ApplicationController

	before_filter :require_sign_out, :except => [:destroy, :sina_connect, :renren_connect, :qq_connect, :google_connect]

	# method: get
	# descryption: the page where user logins
	def index
		@renren_app_id = OOPSDATA[RailsEnv.get_rails_env]["renren_app_id"]
		@renren_redirect_uri = OOPSDATA[RailsEnv.get_rails_env]["renren_redirect_uri"]

		@sina_app_key = OOPSDATA[RailsEnv.get_rails_env]["sina_app_key"]
		@sina_redirect_uri = OOPSDATA[RailsEnv.get_rails_env]["sina_redirect_uri"]
		
		@qq_app_id = OOPSDATA[RailsEnv.get_rails_env]["qq_app_id"]
		@qq_redirect_uri = OOPSDATA[RailsEnv.get_rails_env]["qq_redirect_uri"]
		
		@google_client_id = OOPSDATA[RailsEnv.get_rails_env]["google_client_id"]
		@google_redirect_uri = OOPSDATA[RailsEnv.get_rails_env]["google_redirect_uri"]
	end

	#*kdescryption*: user submits the login form
	#
	#*http* *method*: post
	#
	#*url*: /sessions
	#
	#*params*:
	#* user: the user hash, the keys of which include:
	#  - email
	#  - password
	#
	#*retval*:
	#* true if successfully login
	#* EMAIL_NOT_EXIST
	#* EMAIL_NOT_ACTIVATED
	#* WRONG_PASSWORD
	def create
		login = User.login(params[:user]["email"], params[:user]["password"], @client_ip)
		third_party_info = decrypt_third_party_user_id(params[:third_party_info])
		case login
		when ErrorEnum::EMAIL_NOT_EXIST
			flash[:error] = "帐号不存在!"
			respond_to do |format|
				format.html	{ redirect_to sessions_path and return }
				format.json	{ render :json => ErrorEnum::EMAIL_NOT_EXIST and return }
			end
		when ErrorEnum::EMAIL_NOT_ACTIVATED
			flash[:error] = "您的帐号未激活，请您首先激活帐号"
			respond_to do |format|
				format.html	{ redirect_to intput_activate_email_path and return }
				format.json	{ render :json => ErrorEnum::EMAIL_NOT_ACTIVATED and return }
			end
		when ErrorEnum::WRONG_PASSWORD
			flash[:error] = "密码错误"
			respond_to do |format|
				format.html	{ redirect_to sessions_path and return }
				format.json	{ render :json => ErrorEnum::WRONG_PASSWORD and return }
			end
		else
			User.combine(params[:user]["email"], *third_party_info) if !third_party_info.nil?
			set_login_session(params[:user]["email"])
			flash[:notice] = "已登录"
			respond_to do |format|
				format.html	{ redirect_to home_path and return }
				format.json	{ render :json => true and return }
			end
		end
	end

	#*descryption*: sign out
	#
	#*http* *method*: delete
	#
	#*url*: /sessions
	#
	#*params*:
	#
	#*retval*:
	#* true if successfully logout
	def destroy
		# clear cookie
		set_session(:current_user_email, nil) 
		set_session(:auth_key, nil) 
		# redirect to the welcome page
		respond_to do |format|
			format.html	{ redirect_to root_path and return }
			format.json	{ render :json => true and return }
		end
	end

	# method: get
	# descryption: the page where user inputs the email to reset password
	def forget_password
	end

	#*descryption*: send email to reset password
	#
	#*http* *method*: post
	#
	#*url*: /send_password_email
	#
	#*params*:
	#* email
	#
	#*retval*:
	#* true if successfully send out
	#* ErrorEnum ::EMAIL_NOT_EXIST
	def send_password_email
		if User.user_exist?(params[:email]) == false
			flash[:notice] = "该邮箱未注册，请您注册"
			respond_to do |format|
				format.html { redirect_to registrations_path and return }
				format.json { render :json => ErrorEnum::EMAIL_NOT_EXIST and return }
			end
		end

		user = User.find_by_email(params[:email])
		# send password email
		UserMailer.password_email(user).deliver

		flash[:notice] = "重置密码邮件已发送，请到您的邮箱中点击链接进行密码重置"
		respond_to do |format|
			format.html { redirect_to sessions_path and return }
			format.json { render :json => true and return }
		end
	end

	#*descryption*: user clicks the reset password link
	#
	#*http* *method*: get
	#
	#*url*: /input_new_password
	#
	#*params*:
	#* password_key
	#
	#*retval*:
	#* redirect to forget_password_url if successfully pass the checking
	#* redirect to /500 if it is a wrong link
	def input_new_password
		begin
			password_info_json = Encryption.decrypt_activate_key(params[:password_key])
		rescue
			redirect_to "/500" and return
		end
		redirect_to "/500" and return if password_info_json.nil?
		password_info = JSON.parse(password_info_json)
		if Time.now.to_i - password_info["time"].to_i > OOPSDATA[RailsEnv.get_rails_env]["password_expiration_time"].to_i
			flash[:notice] = "密码重置链接已经过期，请重新发送重置密码链接"
			redirect_to forget_password_url and return
		end
		@email = password_info["email"]
		if User.user_exist?(@email) == false
			redirect_to "/500" and return			# wrong email (link is not generated by our website)
		end
	end

	# method: post
	#*descryption*: user submits the new password
	#
	#*http* *method*: post
	#
	#*url*: /new_password
	#
	#*params*:
	#* user: a hash that has the following keys
	#  - email
	#  - password
	#  - password_confirmation
	#* password_key
	#
	#*retval*:
	#* true if password is reset
	#* ErrorEnum::EMAIL_NOT_EXIST
	def new_password
		begin
			password_info_json = Encryption.decrypt_activate_key(params[:password_key])
		rescue
			respond_to do |format|
				format.html { redirect_to "/500" and return }		# email account does not exist
				format.json { render :json => false and return }		# email account does not exist
			end
		end
		if password_info_json.nil?
			respond_to do |format|
				format.html { redirect_to "/500" and return }		# email account does not exist
				format.json { render :json => false and return }		# email account does not exist
			end
		end
		password_info = JSON.parse(password_info_json)
		if Time.now.to_i - password_info["time"].to_i > OOPSDATA[RailsEnv.get_rails_env]["password_expiration_time"].to_i
			flash[:notice] = "密码重置链接已经过期，请重新发送重置密码链接"
			respond_to do |format|
				format.html { redirect_to forget_password_url and return }		# email account does not exist
				format.json { render :json => ErrorEnum::RESET_PASSWORD_EXPIRED and return }		# email account does not exist
			end
		end
		if password_info["email"] != params[:user]["email"]
			respond_to do |format|
				format.html { redirect_to "/500" and return }		# email account does not exist
				format.json { render :json => ErrorEnum::EMAIL_NOT_EXIST and return }		# email account does not exist
			end
		end

		retval = User.reset_password(params[:user]["email"], params[:user]["password"], params[:user]["password_confirmation"])
		case retval
		when ErrorEnum::EMAIL_NOT_EXIST
			respond_to do |format|
				format.html { redirect_to "/500" and return }		# email account does not exist
				format.json { render :json => ErrorEnum::EMAIL_NOT_EXIST and return }		# email account does not exist
			end
		when ErrorEnum::WRONG_PASSWORD_CONFIRMATION
			respond_to do |format|
				format.html { redirect_to "/500" and return }
				format.json { render :json => ErrorEnum::WRONG_PASSWORD_CONFIRMATION and return }
			end
		else
			flash[:notice] = "密码已重置"
			respond_to do |format|
				format.html { redirect_to sessions_path and return }
				format.json { render :json => true and return }
			end
		end
	end

	def third_party_connect(website, user_id, access_token)
		@third_party_user = ThirdPartyUser.find_by_website_and_user_id(website, user_id.to_s)
		
    # check the TP account from db
    # if not, create a TP account in company db 
    # else, update access_token 
  	if third_party_user.nil?
		  @third_party_user = ThirdPartyUser.create(website, user_id, access_token)
			# ask whether already has a oopsdata account
			#@third_party_info = encrypt_third_party_user_id(website, user_id)
			#render :action => "has_oopsdata_account"
		else
			@third_party_user.update_access_token(access_token)
    end

    # now, the third_party_user should be in company's db.
    # but we should care the former process.
    if !@third_party_user.nil?
      # check the third_party_user had bind OD account.
      if @third_party_user.email.nil? || @third_party_user.email.equal?("") then
        
        if user_login? then 
          #jump to login or register page for OD
          #it will invoke : User.combine()
        else 
          User.combine(session_user.email, @third_party_user.website, @third_party_user.user_id)            
        end
      end
    end
			# login process
			#login = User.third_party_login(email, password, @client_ip)
			#case login
			#when ErrorEnum::EMAIL_NOT_ACTIVATED
			#	flash[:error] = "您的帐号未激活，请您首先激活帐号"
			#	respond_to do |format|
			#		format.html	{ redirect_to intput_activate_email_path and return }
			#		format.json	{ render :json => ErrorEnum::EMAIL_NOT_ACTIVATED and return }
			#	end
			#else
			#	set_login_session(params[:user]["email"])
			#	flash[:notice] = "已登录"
			#	respond_to do |format|
			#		format.html	{ redirect_to home_path and return }
			#		format.json	{ render :json => true and return }
			#	end
			#end
		
		render :text => @user_id
	end

	def renren_connect
		access_token_params = {"client_id" => OOPSDATA[RailsEnv.get_rails_env]["renren_api_key"],
			"client_secret" => OOPSDATA[RailsEnv.get_rails_env]["renren_secret_key"],
			"redirect_uri" => OOPSDATA[RailsEnv.get_rails_env]["renren_redirect_uri"],
			"grant_type" => "authorization_code",
			"code" => params[:code]}
		retval = Tool.send_post_request("https://graph.renren.com/oauth/token", access_token_params, true)
		response_data = JSON.parse(retval.body)
		user_id = response_data["user"]["id"]
		third_party_connect("renren", user_id)
	end

	def sina_connect
		access_token_params = {"client_id" => OOPSDATA[RailsEnv.get_rails_env]["sina_app_key"],
			"client_secret" => OOPSDATA[RailsEnv.get_rails_env]["sina_app_secret"],
			"redirect_uri" => OOPSDATA[RailsEnv.get_rails_env]["sina_redirect_uri"],
			"grant_type" => "authorization_code",
			"code" => params[:code]}
		retval = Tool.send_post_request("https://api.weibo.com/oauth2/access_token", access_token_params, true)
		response_data = JSON.parse(retval.body)
		user_id = response_data["uid"]
		third_party_connect("sina", user_id)
	end

	def qq_connect
		access_token_params = {"client_id" => OOPSDATA[RailsEnv.get_rails_env]["qq_app_id"],
			"client_secret" => OOPSDATA[RailsEnv.get_rails_env]["qq_app_key"],
			"redirect_uri" => OOPSDATA[RailsEnv.get_rails_env]["qq_redirect_uri"],
			"grant_type" => "authorization_code",
			"state" => Time.now.to_i,
			"code" => params[:code]}
		retval = Tool.send_post_request("https://graph.qq.com/oauth2.0/token", access_token_params, true)
		@access_token, @expires_in = *(retval.body.split('&').map { |ele| ele.split('=')[1] })
		retval = Tool.send_get_request("https://graph.qq.com/oauth2.0/me?access_token=#{@access_token}", true)
		response_data = JSON.parse(retval.body.split(' ')[1])
		user_id = response_data["openid"]
		third_party_connect("qq", user_id)
	end

	def google_connect
		access_token_params = {"client_id" => OOPSDATA[RailsEnv.get_rails_env]["google_client_id"],
			"client_secret" => OOPSDATA[RailsEnv.get_rails_env]["google_client_secret"],
			"redirect_uri" => OOPSDATA[RailsEnv.get_rails_env]["google_redirect_uri"],
			"grant_type" => "authorization_code",
			"code" => params[:code]}
		retval = Tool.send_post_request("https://accounts.google.com/o/oauth2/token", access_token_params, true)
		response_data = JSON.parse(retval.body)
		@access_token = response_data["access_token"]
		retval = Tool.send_get_request("https://www.googleapis.com/oauth2/v1/userinfo?access_token=#{@access_token}", true)
		response_data = JSON.parse(retval.body)
		user_id = response_data["id"]
		third_party_connect("google", user_id)
	end

  def qihu_connect
		access_token_params = {"client_id" => OOPSDATA[RailsEnv.get_rails_env]["qihu_app_key"],
			"client_secret" => OOPSDATA[RailsEnv.get_rails_env]["qihu_app_secret"],
			"redirect_uri" => OOPSDATA[RailsEnv.get_rails_env]["qihu_redirect_uri"],
			"grant_type" => "authorization_code",
      #"scope" => "basic",
			"code" => params[:code]
      }
		retval = Tool.send_post_request("https://openapi.360.cn/oauth2/access_token", access_token_params, true)
		response_data = JSON.parse(retval.body)
		@access_token = response_data["access_token"]
		retval = Tool.send_get_request("https://openapi.360.cn/user/me.json?access_token=#{@access_token}", true)
		response_data = JSON.parse(retval.body)
		user_id = response_data["id"]
		third_party_connect("qihu", user_id)
  end 

	private

	# method: in-accessible
	# description: help set session for an email account
	def set_login_session(email)
		set_session(:current_user_email, params[:user]["email"]) 
		auth_key = Encryption.encrypt_auth_key("#{email}&#{Time.now.to_i.to_s}")
		set_session(:auth_key, auth_key)
		User.set_auth_key(email, auth_key)
	end

	def encrypt_third_party_user_id(website, user_id)
		return Encryption.encrypt_third_party_user_id({"website" => website, "user_id" => user_id}.to_json)
	end

	def decrypt_third_party_user_id(string)
		begin
			h = JSON.parse(Encryption.decrypt_third_party_user_id(string))
			return [h["webiste"], h["user_id"]]
		rescue
			return nil
		end
	end 
	
end
