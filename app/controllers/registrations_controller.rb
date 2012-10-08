# encoding: utf-8
require 'error_enum'
require 'tool'
require 'encryption'

class RegistrationsController < ApplicationController

	before_filter :require_sign_out, :except => [:email_illegal, :destroy]

	# method: get
	# descryption: the page where user inputs the registration form
	def index
	  flash.keep(:google_email)
	  flash.keep(:third_party_info)
	end
	
	#*descryption*: user submits registration form
	#
	#*http* *method*: post
	#
	#*url*: /registrations
	#
	#*params*:
	#* user: the user hash, the keys of which include:
	#  - email
	#  - username
	#  - password
	#  - password_confirmation
	#* third_party_info: a key if user registrates with a third party website account
	#
	#*retval*:
	#* true if successfully registrated
	#* ErrorEnum ::ILLEGAL_EMAIL
	#* ErrorEnum ::EMAIL_ACTIVATED
	#* ErrorEnum ::EMAIL_NOT_ACTIVATED
	#* ErrorEnum ::WRONG_PASSWORD_CONFIRMATION
	def create
		# create user model
		user = User.create_new_registered_user(params[:user], @current_user)
		case user
		when ErrorEnum::ILLEGAL_EMAIL
			flash[:notice] = "请输入正确的邮箱地址"
			respond_to do |format|
				format.html	{ redirect_to registrations_path and return }
				format.json { render_json_e(ErrorEnum::ILLEGAL_EMAIL) and return }
			end
		when ErrorEnum::EMAIL_EXIST
			flash[:notice] = "邮箱已经存在"
			respond_to do |format|
				format.html	{ redirect_to sessions_path and return }
				format.json { render_json_e(ErrorEnum::EMAIL_EXIST) and return }
			end
		when ErrorEnum::USERNAME_EXIST
			flash[:notice] = "用户名已经存在"
			respond_to do |format|
				format.html	{ redirect_to sessions_path and return }
				format.json { render_json_e(ErrorEnum::USERNAME_EXIST) and return }
			end
		when ErrorEnum::WRONG_PASSWORD_CONFIRMATION
			flash[:notice] = "输入密码不一致"
			respond_to do |format|
				format.html	{ redirect_to registrations_path and return }
				format.json { render_json_e(ErrorEnum::WRONG_PASSWORD_CONFIRMATION) and return }
			end
		else # create user_information model
			third_party_info = decrypt_third_party_user_id(params[:third_party_info])
      		User.combine(params[:user]["email"], *third_party_info) if !third_party_info.nil?
			# automatically activate for google user
			if third_party_info && third_party_info[0]=="google"
				activate_info = {"email" => params[:user]["email"], "time" => Time.now.to_i}
				User.activate(activate_info)
			else
				Jobs.start(:EmailSendingJob, Time.now.to_i, email_type: "welcome", user_email: user.email)
				# UserMailer.welcome_email(user).deliver
			end
			# succesfully registered
			flash[:notice] = "注册成功，请到您的邮箱中点击激活链接进行激活" if user.status == 0
			flash[:notice] = "注册成功，Google邮箱默认已激活" if user.status == 1
			respond_to do |format|
				format.html	{ redirect_to sessions_path and return }
				format.json	{ render_json_s and return }
			end
		end
	end

	#*descryption*: create a visitor user
	#
	#*http* *method*: post
	#
	#*url*: /registrations/create_visitor
	#
	#*params*:
	#
	#*retval*:
	#* auth_key
	def create_new_visitor_user
		# create user model
		auth_key = User.create_new_visitor_user
		render_json_s(auth_key) and return
	end

	#*description*: check whether email is illegal
	#
	#*http* *method*: get or post
	#
	#*url*: /check_email
	#
	#*params*:
	#* email: email address to be checked
	#
	#*retval*:
	#* true if it is illegal
	#* false if it is legal
	def email_illegal
		email_legal = !Tool.email_illegal?(params[:email])
		respond_to do |format|
			format.html	{ render :text => email_legal and return }
			format.json	{ render_json_s(email_legal) and return }
		end
	end

	#*description*: submit email address to send activate email
	#
	#*http* *method*: post
	#
	#*url*: /send_activate_email
	#
	#*params*:
	#* email
	#
	#*retval*:
	#* true if the activate email is sent out
	#* Errorenum ::EMAIL_NOT_EXIST
	#* Errorenum ::EMAIL_ACTIVATED
	def send_activate_email
	
		user = User.find_by_email(params[:user]["email"])

		if user.nil?
			flash[:notice] = "该邮箱未注册，请您注册"
			respond_to do |format|
				format.html	{ redirect_to registrations_path and return }
				format.json	{ render_json_e(ErrorEnum::USER_NOT_EXIST) and return }
			end
		elsif user.is_activated
			flash[:notice] = "该帐号已激活，请您登录"
			respond_to do |format|
				format.html	{ redirect_to sessions_path and return }
				format.json	{ render_json_e(ErrorEnum::USER_ACTIVATED) and return }
			end
		end
		
		# send activate email
		Jobs.start(:EmailSendingJob, Time.now.to_i, email_type: "activate", user_email: user.email)
		# UserMailer.activate_email(user).deliver

		flash[:notice] = "激活邮件已发送，请到您的邮箱中点击激活链接进行激活"
		respond_to do |format|
			format.html	{ redirect_to sessions_path and return }
			format.json	{ render_json_s }
		end
	end

	#*description*: click activate link to activate an user
	#
	#*http* *method*: get
	#
	#*url*: /activate
	#
	#*params*:
	#* activate_key
	#
	#*retval*:
	#* redirect to sessions_path if successfully activated
	#* redirect to input_activate_email_path if expired
	#* redirect to /500 if email account does not exist
	def activate
		begin
			activate_info_json = Encryption.decrypt_activate_key(params[:activate_key])
			activate_info = JSON.parse(activate_info_json)
		rescue
			redirect_to "/500" and return
		end
		activate_retval = User.activate(activate_info)
		case activate_retval
		when ErrorEnum::ACTIVATE_EXPIRED
			flash[:notice] = "您的激活链接已经过期，请您重新发送激活邮件进行激活"
			redirect_to input_activate_email_path and return
		when ErrorEnum::USER_NOT_EXIST
			redirect_to "/500" and return			# email account does not exist (link is not generated by our website)
		when true
			flash[:notice] = "您已经成功激活，请登录"
			redirect_to sessions_path and return
		else
			redirect_to "/500" and return			# unknow error
		end
	end

	# delete account
	def destroy
		retval = @current_user.destroy
		case retval
		when ErrorEnum::USER_NOT_EXIST
			flash[:error] = "帐号不存在!"
			respond_to do |format|
				format.html	{ redirect_to home_path and return }
				format.json	{ render_json_e(ErrorEnum::USER_NOT_EXIST) and return }
			end
		else
			respond_to do |format|
				flash[:notice] = "已经成功注销帐号"
				format.html	{ redirect_to root_path and return }
				format.json	{ render_json_s and return }
			end
		end
		
	end

end
