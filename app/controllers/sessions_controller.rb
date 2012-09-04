# encoding: utf-8
require 'encryption'
require 'error_enum'
require 'tool'
class SessionsController < ApplicationController

	before_filter :require_sign_out, :only => [:create]
	before_filter :require_sign_in, :only => [:destroy, :init_basic_info, :obtain_user_attr_survey, :init_user_attr_survey, :skip_init_step, :update_user_info, :reset_password, :get_level_information]

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

	#*descryption*: user signs in with auth_key
	#
	#*http* *method*: post
	#
	#*url*: /sessions/login_with_auth_key
	#
	#*params*:
	#* auth_key: the user hash, the keys of which include:
	def login_with_auth_key
		login = User.login_with_auth_key(params[:auth_key])
		respond_to do |format|
			format.json	{ render_json_auto(login) and return }
		end
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
		login = User.login(params[:user]["email_username"], params[:user]["password"], @remote_ip, params[:_client_type], params[:keep_signed_in])
		third_party_info = decrypt_third_party_user_id(params[:third_party_info])
		case login
		when ErrorEnum::USER_NOT_EXIST
			respond_to do |format|
				format.json	{ render_json_e(ErrorEnum::USER_NOT_EXIST) and return }
			end
		when ErrorEnum::USER_NOT_ACTIVATED
			respond_to do |format|
				format.json	{ render_json_e(ErrorEnum::USER_NOT_ACTIVATED) and return }
			end
		when ErrorEnum::WRONG_PASSWORD
			respond_to do |format|
				format.json	{ render_json_e(ErrorEnum::WRONG_PASSWORD) and return }
			end
		when false
			respond_to do |format|
				format.json	{ render_json_e(ErrorEnum::UNKNOWN_ERROR) and return }
			end
		else
			User.combine(params[:user]["email_username"], *third_party_info) if !third_party_info.nil?
			respond_to do |format|
				format.json	{ render_json_s(login) and return }
			end
		end
	end

	def show
		user = user.find_by_auth_key(params[:id])
		render_json_auto(user.nil?) and return
	end
	
	def update_user_info
		retval = @current_user.update_basic_info(params[:user_info])
		case retval
		when true
			flash[:notice] = "更新个人信息成功"
			respond_to do |format|
				format.html	{ redirect_to home_path and return }
				format.json	{ render_json_s and return }
			end
		else
			respond_to do |format|
				format.html	{ redirect_to "/500" and return }
				format.json	{ render_json_e(ErrorEnum::UNKNOWN_ERROR) and return }
			end
		end
	end

	def init_basic_info
		retval = @current_user.init_basic_info(params[:user_info])
		case retval
		when true
			flash[:notice] = "更新个人信息成功"
			respond_to do |format|
				format.html	{ redirect_to home_path and return }
				format.json	{ render_json_s and return }
			end
		else
			respond_to do |format|
				format.html	{ redirect_to "/500" and return }
				format.json	{ render_json_e(ErrorEnum::UNKNOWN_ERROR) and return }
			end
		end
	end

	def init_user_attr_survey
		retval = @current_user.init_attr_survey(params[:survey_id], params[:answer])
		respond_to do |format|
			format.json	{ render_json_s(retval) and return }
		end
	end

	def obtain_user_attr_survey
		questions = Survey.get_user_attr_survey
		respond_to do |format|
			format.json { render_json_s(questions) and return }
		end
	end

	def skip_init_step
		retval = @current_user.skip_init_step
		case retval
		when false 
			respond_to do |format|
				format.html	{ redirect_to "/500" and return }
				format.json	{ render_json_e(ErrorEnum::UNKNOWN_ERROR) and return }
			end
		else
			flash[:notice] = "成功跳到下一步"
			respond_to do |format|
				format.html	{ redirect_to home_path and return }
				format.json	{ render_json_s({"status" => retval}) and return }
			end
		end
	end

	################# this should moved to the web client side ###############
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
		User.logout(params[:auth_key])
		# redirect to the welcome page
		respond_to do |format|
			format.html	{ redirect_to root_path and return }
			format.json	{ render_json_s and return }
		end
	end

	# method: get
	# descryption: the page where user inputs the email to reset password
	def forget_password
	end
	#############################################################################

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
		user = User.find_by_email(params[:email])
		if user.nil?
			flash[:notice] = "该邮箱未注册，请您注册"
			respond_to do |format|
				format.html { redirect_to registrations_path and return }
				format.json { render_json_e(ErrorEnum::USER_NOT_EXIST) and return }
			end
		end

		# send password email
		UserMailer.password_email(user).deliver

		flash[:notice] = "重置密码邮件已发送，请到您的邮箱中点击链接进行密码重置"
		respond_to do |format|
			format.html { redirect_to sessions_path and return }
			format.json { render_json_s and return }
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
			redirect_to :action => "forget_password" and return
		end
		user = User.find_by_email(password_info["email"])
		redirect_to "/500" and return if user.nil?		# wrong email (link is not generated by our website)
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
				format.json { render_json_e(ErrorEnum::USER_NOT_EXIST) and return }		# email account does not exist
			end
		end
		if password_info_json.nil?
			respond_to do |format|
				format.html { redirect_to "/500" and return }		# email account does not exist
				format.json { render_json_e(ErrorEnum::USER_NOT_EXIST) and return }		# email account does not exist
			end
		end
		password_info = JSON.parse(password_info_json)
		if Time.now.to_i - password_info["time"].to_i > OOPSDATA[RailsEnv.get_rails_env]["password_expiration_time"].to_i
			flash[:notice] = "密码重置链接已经过期，请重新发送重置密码链接"
			respond_to do |format|
				format.html { redirect_to :action => "forget_password" and return }		# email account does not exist
				format.json { render_json_e(ErrorEnum::RESET_PASSWORD_EXPIRED) and return }		# email account does not exist
			end
		end
		if password_info["email"] != params[:user]["email"]
			respond_to do |format|
				format.html { redirect_to "/500" and return }		# email account does not exist
				format.json { render_json_e(ErrorEnum::USER_NOT_EXIST) and return }		# email account does not exist
			end
		end

		retval = User.reset_password(params[:user]["email"], params[:user]["password"], params[:user]["password_confirmation"])
		case retval
		when ErrorEnum::USER_NOT_EXIST
			respond_to do |format|
				format.html { redirect_to "/500" and return }		# email account does not exist
				format.json { render_json_e(ErrorEnum::USER_NOT_EXIST) and return }		# email account does not exist
			end
		when ErrorEnum::WRONG_PASSWORD_CONFIRMATION
			respond_to do |format|
				format.html { redirect_to "/500" and return }
				format.json { render_json_e(ErrorEnum::WRONG_PASSWORD_CONFIRMATION) and return }		# email account does not exist
			end
		else
			flash[:notice] = "密码已重置"
			respond_to do |format|
				format.html { redirect_to sessions_path and return }
				format.json { render_json_s and return }
			end
		end
	end

	#*descryption*: user resets the new password
	#
	#*http* *method*: post
	#
	#*url*: /reset_password
	#
	#*params*:
	#* old_password
	#* new_password
	#
	#*retval*:
	#* true if succeed
	#* ErrorEnum ::WRONG_PASSWORD 
	def reset_password
		reset_password_retval = @current_user.reset_password(params["old_password"], params["new_password"], params["new_password_confirmation"])
		respond_to do |format|
			format.json { render_json_s(reset_password_retval) and return }
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
		token_data = QqUser.get_access_token(params[:code])
		qq_user = QqUser.save_tp_user(token_data)
		deal_connect(qq_user)
	end 

	#*descryption*: be involved from google connect
	#
	#*params*:
	#* code
	def google_connect
		token_data = GoogleUser.get_access_token(params[:code])
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

	def third_party_authorized
		# try to find the third party user in the database, if not, create a new one
		tp_user = ThirdPartyUser.find_by_website_and_user_id(params[:third_party_website], params[:third_party_user_id])
		tp_user = ThirdPartyUser.create_third_party_user(params) if tp_user.nil?

		if tp_user.is_bound && user_signed_in?
			# bound and signed in
			respond_to do |format|
				format.json { render_json_s({"binding" => tp_user.is_bound(@current_user)}) and return }
			end
		elsif tp_user.is_bound && !user_signed_in?
			retval = User.login(@current_user.email, Encryption.decrypt_password(@current_user.password), @client_ip)
			respond_to do |format|
				format.json { render_json_s(retval) and return }
			end
		elsif !tp_user.is_bound && user_signed_in
			respond_to do |format|
				format.json { render_json_s({"binding" => tp_user.bind(@current_user)}) and return }
			end
		else
			google_user = tp_user.website == "google"? tp_user.google_email : nil
			third_party_info = encrypt_third_party_user_id(tp_user.website, tp_user.user_id)
			respond_to do |format|
				format.json { render_json_s({"third_party_info" => third_party_info, "google_user" => google_user}) and return }
			end
		end

	end
	
	#*descryption*: deal with the third party user login logic
	#
	#*params*:
	#* status
	#* tp_user
	def deal_connect(tp_user)
		if tp_user.is_bound && user_signed_in?
			flash[:error] = "不能重复绑定第三方网站"
			redirect_to home_path and return
		elsif tp_user.is_bound && !user_signed_in?
			retval = User.login(@current_user.email, Encryption.decrypt_password(@current_user.password), @client_ip)
			case login
			when ErrorEnum::USER_NOT_ACTIVATED
				flash[:error] = "您的帐号未激活，请您首先激活帐号"
				redirect_to input_activate_email_path and return
			when true
				flash[:notice] = "登录成功"
				redirect_to home_path and return
			else
				redirect_to "/500" and return
			end
		elsif !tp_user.is_bound && user_signed_in?
			tp_user.bind(@current_user)
			flash[:notice] = "绑定成功"
			redirect_to home_path and return
		else # !tp_user.is_bound && !user_signed_in
			flash[:notice] = "第三方登录成功，请登录OopsData的帐号进行绑定。"
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
