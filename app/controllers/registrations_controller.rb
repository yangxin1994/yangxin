# encoding: utf-8
require 'error_enum'
require 'tool'
class RegistrationsController < ApplicationController

	before_filter :require_sign_out, :except => [:email_illegal]

	# method: get
	# descryption: the page where user inputs the registration form
	def index
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
	#  - password
	#  - password_confirmation
	#  - username
	#* user_information: the user information hash, the keys of which include:
	#  - email
	#  - realname
	#  - address
	#  - zipcode
	#  - telephone
	#  - gender
	#  - marriage
	#  - education
	#  - birthday
	#  - location
	#  - family_incoming
	#  - personal_incoming
	#  - position
	#  - industry
	#
	#*retval*:
	#* true if successfully registrated
	#* ErrorEnum ::ILLEGAL_EMAIL
	#* ErrorEnum ::EMAIL_ACTIVATED
	#* ErrorEnum ::EMAIL_NOT_ACTIVATED
	#* ErrorEnum ::WRONG_PASSWORD_CONFIRMATION
	def create
		# create user model
		user = User.check_and_create_new(params[:user])
		case user
		when ErrorEnum::ILLEGAL_EMAIL
			flash[:notice] = "请输入正确的邮箱地址"
			respond_to do |format|
				format.html	{ redirect_to registrations_path and return }
				format.json	{ render :json => ErrorEnum::ILLEGAL_EMAIL and return }
			end
		when ErrorEnum::EMAIL_ACTIVATED
			flash[:notice] = "邮箱#{params[:user]["email"]}已经注册，请直接登录"
			respond_to do |format|
				format.html	{ redirect_to sessions_path and return }
				format.json	{ render :json => ErrorEnum::EMAIL_ACTIVATED and return }
			end
		when ErrorEnum::EMAIL_NOT_ACTIVATED
			flash[:notice] = "邮箱#{params[:user]["email"]}已经注册，但未激活，请您首先激活帐号"
			respond_to do |format|
				format.html	{ redirect_to sessions_path and return }
				format.json	{ render :json => ErrorEnum::EMAIL_NOT_ACTIVATED }
			end
		when ErrorEnum::WRONG_PASSWORD_CONFIRMATION
			flash[:notice] = "输入密码不一致"
			respond_to do |format|
				format.html	{ redirect_to registrations_path and return }
				format.json	{ render :json => ErrorEnum::WRONG_PASSWORD_CONFIRMATION and return }
			end
		else # create user_information model
			user_information = UserInformation.update(params[:user_information])
			# send registration email
			UserMailer.welcome_email(user).deliver
			# succesfully registered
			flash[:notice] = "注册成功，请到您的邮箱中点击激活链接进行激活"
			respond_to do |format|
				format.html	{ redirect_to sessions_path and return }
				format.json	{ render :json => true and return }
			end
		end
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
			format.json	{ render :json => email_legal and return }
		end
	end


	# method: get
	# descryption: show the page where user can input the email for activating
	def input_activate_email
	end

	#*description*: submit email address to send activate email
	#
	#*http* *method*: post
	#
	#*url*: /send_activate_email
	#
	#*params*:
	#* user: a hash which has the following key
	#  - email
	#
	#*retval*:
	#* true if the activate email is sent out
	#* Errorenum ::EMAIL_NOT_EXIST
	#* Errorenum ::EMAIL_ACTIVATED
	def send_activate_email
		if User.user_exist?(params[:user]["email"]) == false
			flash[:notice] = "该邮箱未注册，请您注册"
			respond_to do |format|
				format.html	{ redirect_to registrations_path and return }
				format.json	{ render :json => ErrorEnum::EMAIL_NOT_EXIST and return }
			end
		elsif User.user_activate?(params[:user]["email"])
			flash[:notice] = "该帐号已激活，请您登录"
			respond_to do |format|
				format.html	{ redirect_to sessions_path and return }
				format.json	{ render :json => ErrorEnum::EMAIL_ACTIVATED and return }
			end
		end

		user = User.find_by_email(params[:user]["email"])
		# send activate email
		UserMailer.activate_email(user).deliver

		flash[:notice] = "激活邮件已发送，请到您的邮箱中点击激活链接进行激活"
		respond_to do |format|
			format.html	{ redirect_to sessions_path and return }
			format.json	{ render :json => true }
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
		activate_info_json = Encryption.decrypt_activate_key(params[:activate_key])
		@activate_info = JSON.parse(activate_info_json)
		activate_retval = User.activate(@activate_info)
		if activate_retval == true
			flash[:notice] = "您已经成功激活，请登录"
			redirect_to sessions_path and return
		elsif activate_retval == -5
			flash[:notice] = "您的激活链接已经过期，请您重新发送激活邮件进行激活"
			redirect_to input_activate_email_path and return
		else
			redirect_to "/500" and return			# email account does not exist (link is not generated by our website)
		end
	end

end
