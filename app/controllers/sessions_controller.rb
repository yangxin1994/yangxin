# encoding: utf-8
require 'encryption'
require 'error_enum'
require 'tool'
class SessionsController < ApplicationController

	before_filter :require_sign_out, :except => [:destroy, :sina_connect, :renren_connect, :qq_connect, :google_connect]
	before_filter :require_sign_in, :only => [:destroy, :basic_info]

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

    @qihu_client_id = OOPSDATA[RailsEnv.get_rails_env]["qihu_app_key"]
    @qihu_redirect_uri = OOPSDATA[RailsEnv.get_rails_env]["qihu_redirect_uri"]
    
  end
	#*descryption*: user submits the login form
	#
	#*http* *method*: post
	#
	#*url*: /sessions
	#
	#*params*:
	#* user: the user hash, the keys of which include:
	#  - email
	#  - password
	#* keep_signed_in
	#
	#*retval*:
	#* true if successfully login
	#* EMAIL_NOT_EXIST
	#* EMAIL_NOT_ACTIVATED
	#* WRONG_PASSWORD
	def create
		login = User.login(params[:user]["email_username"], params[:user]["password"], @client_ip)
		third_party_info = decrypt_third_party_user_id(params[:third_party_info])
		case login
		when ErrorEnum::USER_NOT_EXIST
			flash[:error] = "帐号不存在!"
			respond_to do |format|
				format.html	{ redirect_to sessions_path and return }
				format.json	{ render :json => ErrorEnum::EMAIL_NOT_EXIST and return }
			end
		when ErrorEnum::USER_NOT_ACTIVATED
			flash[:error] = "您的帐号未激活，请您首先激活帐号"
			respond_to do |format|
				format.html	{ redirect_to input_activate_email_path and return }
				format.json	{ render :json => ErrorEnum::EMAIL_NOT_ACTIVATED and return }
			end
		when ErrorEnum::WRONG_PASSWORD
			flash[:error] = "密码错误"
			respond_to do |format|
				format.html	{ redirect_to sessions_path and return }
				format.json	{ render :json => ErrorEnum::WRONG_PASSWORD and return }
			end
		when true
			User.combine(params[:user]["email_username"], *third_party_info) if !third_party_info.nil?
			set_login_cookie(params[:user]["email_username"], params[:keep_signed_in])
			flash[:notice] = "登录成功"
			respond_to do |format|
				format.html	{ redirect_to home_path and return }
				format.json	{ render :json => true and return }
			end
		else
			respond_to do |format|
				format.html	{ redirect_to "/500" and return }
				format.json	{ render :json => "unknow error" and return }
			end
		end
	end

	def basic_info
		retval = @current_user.user_init_basic_info(params[:user_info)
		case retval
		when true
			flash[:notice] = "更新个人信息成功"
			respond_to do |format|
				format.html	{ redirect_to home_path and return }
				format.json	{ render :json => true and return }
			end
		else
			respond_to do |format|
				format.html	{ redirect_to "/500" and return }
				format.json	{ render :json => "unknow error" and return }
			end
		end
	end

	def user_attr_survey
		retval = @current_user.user_init_attr_survey(params[:answer)
		case retval
		when true
			flash[:notice] = "更新个人信息成功"
			respond_to do |format|
				format.html	{ redirect_to home_path and return }
				format.json	{ render :json => true and return }
			end
		else
			respond_to do |format|
				format.html	{ redirect_to "/500" and return }
				format.json	{ render :json => "unknow error" and return }
			end
		end
	end

	def skip_user_init
		retval = @current_user.skip_user_init
		case retval
		when true
			flash[:notice] = "成功跳到下一步"
			respond_to do |format|
				format.html	{ redirect_to home_path and return }
				format.json	{ render :json => true and return }
			end
		else 
			respond_to do |format|
				format.html	{ redirect_to "/500" and return }
				format.json	{ render :json => "unknow error" and return }
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
		set_logout_cookie
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
	#* show the password input form if successfully pass the checking
	#* redirect to forget_password_url if expired
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

	#*descryption*: be involved from renren connect
	#
	#*params*:
	#* code
	def renren_connect
		token_data = RenrenUser.get_access_token(params[:code])
		renren_user = RenrenUser.save_tp_user(token_data)
		deal_connect(renren_user)
	end 

  #*descryption*: be involved from sina connect
	#
	#*params*:
	#* code
	def sina_connect
		token_data = SinaUser.get_access_token(params[:code])
		sina_user = SinaUser.save_tp_user(token_data)
		deal_connect(sina_user)
	end 

  #*descryption*: be involved from qq connect
	#
	#*params*:
	#* code
	def qq_connect
		token_data = QqUser.token(params[:code])
		qq_user = QqUser.save_tp_user(token_data)
		deal_connect(qq_user)
	end 

  #*descryption*: be involved from google connect
	#
	#*params*:
	#* code
	def google_connect
	  token_data = GoogleUser.token(params[:code])
	  google_user = GoogleUser.save_tp_user(token_data)
	  deal_connect(google_user)
	end

  #*descryption*: be involved from qihu connect
	#
	#*params*:
	#* code
  def qihu_connect
    flash[:notice] = "尚未支持奇虎第三方登录。"
    render :action => "index", :controller => "sessions"
    
	  raise "Do not have :code params." if params[:code].nil?
	  status, qihu_user = QihuUser.token(params[:code])
	  deal_connect(status, qihu_user)
  end 
	
	#*descryption*: deal with the third party user login logic
	#
	#*params*:
	#* status
	#* tp_user
	def deal_connect(tp_user)
		if tp_user.is_bound && user_signed_in
			flash[:error] = "不能重复绑定第三方网站"
			redirect_to home_path and return
		elsif tp_user.is_bound && !user_signed_in
      retval = User.login(@current_user.email, Encryption.decrypt_password(@current_user.password), @client_ip)
			case login
			when ErrorEnum::USER_NOT_ACTIVATED
				flash[:error] = "您的帐号未激活，请您首先激活帐号"
				redirect_to input_activate_email_path and return
			when true
				set_login_cookie(@current_user._id)
				flash[:notice] = "登录成功"
				redirect_to home_path and return
			else
				flash[:notice] = "unknown error"
				redirect_to "/500" and return
			end
		elsif !tp_user.is_bound && user_signed_in
			tp_user.bind(@current_user)
			flash[:notice] = "绑定成功"
			redirect_to home_path and return
		else # !tp_user.is_bound && !user_signed_in
			@gmail = tp_user.website == "google"? tp_user.google_email : nil
      @tp_info= encrypt_third_party_user_id(tp_user.website, tp_user.user_id)
			render :action => "index"
		end
	end

	private

	def encrypt_third_party_user_id(website, user_id)
		return Encryption.encrypt_third_party_user_id({"website" => website, "user_id" => user_id}.to_json)
	end
end
