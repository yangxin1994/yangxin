# encoding: utf-8
require 'encryption'
require 'error_enum'
require 'tool'
class SessionsController < ApplicationController

	before_filter :require_sign_in, :only => [:destroy, :init_basic_info, :obtain_user_attr_survey, :init_user_attr_survey, :skip_init_step, :update_user_info, :reset_password, :get_level_information]

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
		login = User.login_with_email(params[:user]["email_username"], params[:user]["password"], @remote_ip, params[:_client_type], params[:keep_signed_in], params[:third_party_user_id])
		render_json_auto(login) and return
	end

	def update_user_info
		retval = @current_user.update_basic_info(params[:user_info])
		render_json_auto(retval) and return
	end

	def init_basic_info
		retval = @current_user.init_basic_info(params[:user_info])
		render_json_auto(retval) and return
	end

	def init_user_attr_survey
		retval = @current_user.init_attr_survey(params[:survey_id], params[:answer])
		render_json_s(retval) and return
	end

	def obtain_user_attr_survey
		questions = Survey.get_user_attr_survey
		render_json_s(questions) and return
	end

	def skip_init_step
		retval = @current_user.skip_init_step
		render_json_s(retval) and return
	end

	def destroy
		User.logout(params[:auth_key])
		render_json_s and return
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
		user = User.find_by_email(params[:email])
		render_json_e(ErrorEnum::USER_NOT_EXIST) and return if user.nil?
		TaskClient.create_task({ task_type: "email",
								params: { email_type: "password",
										email: user.email,
										callback: params[:callback] } })
		render_json_s and return
	end

	# method: post
	#*descryption*: user submits the new password
	#
	#*http* *method*: post
	#
	#*url*: /new_password
	#
	#*params*:
	#  password
	#  password_confirmation
	#* password_key
	#
	#*retval*:
	#* true if password is reset
	#* ErrorEnum::EMAIL_NOT_EXIST
	def new_password
		begin
			password_info_json = Encryption.decrypt_activate_key(params[:password_key])
			password_info = JSON.parse(password_info_json)
		rescue
			render_json_e(ErrorEnum::USER_NOT_EXIST) and return	# email account does not exist
		end
		if Time.now.to_i - password_info["time"].to_i > OOPSDATA[RailsEnv.get_rails_env]["password_expiration_time"].to_i
			render_json_e(ErrorEnum::RESET_PASSWORD_EXPIRED) and return
		end
		retval = User.reset_password(password_info["email"], params[:password], params[:password_confirmation])
		render_json_auto(retval)
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
		retval = @current_user.reset_password(params[:old_password], params[:new_password], params[:new_password_confirmation])
		render_json_auto(retval) and return
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
		retval = User.login_with_auth_key(params[:auth_key])
		render_json_auto(retval) and return
	end

	#*descryption*: user signs in with code from third party website
	#
	#*http* *method*: post
	#
	#*url*: /sessions/login_with_code
	#
	#*params*:
	#* code: the code provided by the third party website
	#* website: the name of the third party website
	def login_with_code
		# with the code, get the token data
		# => for sina, renren, the user id is in response data
		# => for google, qq, another request is needed to get the user id
		response_data = ThirdPartyUser.get_access_token(params[:website], params[:code])
		# with the response data, find the third party user in database, or create one
		tp_user = ThirdPartyUser.find_or_create_user(params[:website], response_data)
		render_json_e(tp_user) and return if tp_user.class != ThirdPartyUser
		# check whether this user has been bound to one quill account
		user = tp_user.user
		if user.nil?
			# new to quill
			render_json_auto({third_party_user_id: tp_user._id}) and return
		else
			# login
			retval = user.login(@remote_ip, params[:client_type])
			render_json_auto(retval) and return
		end
	end
end
