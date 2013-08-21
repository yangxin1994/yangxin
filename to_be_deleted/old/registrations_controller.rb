# encoding: utf-8
require 'error_enum'
require 'tool'
require 'encryption'

class RegistrationsController < ApplicationController
	
	def create
		retval = User.create_new_user(
			params[:email_mobile],
			params[:password],
			@current_user,
			params[:third_party_user_id],
			params[:callback])
		render_json_auto(retval) and return
	end

	def send_activate_key
		user = nil
		if params[:email_mobile].match(/\w+([-+.]\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*/)  ## match email
			user = User.find_by_email(params[:email_mobile].downcase)
		elsif params[:email_mobile].match(/^\d{11}$/)  ## match mobile
			user = User.find_by_mobile(params[:email_mobile])
		end
		render_json_e(ErrorEnum::USER_NOT_EXIST) and return if user.nil?
		render_json_e(ErrorEnum::USER_NOT_REGISTERED) and return if user.status == 0
		render_json_e(ErrorEnum::USER_ACTIVATED) and return if user.is_activated
		if params[:email_mobile].match(/^\d{11}$/)
			active_code = Tool.generate_active_mobile_code
			user.sms_verification_code = active_code
			user.sms_verification_expiration_time  = (Time.now + 2.hours).to_i
			user.save
			SmsWorker.perform_async("activate", user.mobile, "", :active_code => active_code)
		else
			EmailWorker.perform_async("welcome", user.email, params[:callback])
		end
		render_json_s and return
	end

	#注册后邮箱激活
	def email_activate
		begin
			activate_info_json = Encryption.decrypt_activate_key(params[:activate_key])
			activate_info = JSON.parse(activate_info_json)
		rescue
			render_json_e(ErrorEnum::ILLEGAL_ACTIVATE_KEY) and return
		end
		retval = User.activate("email", activate_info, @remote_ip, params[:_client_type])
		render_json_auto(retval) and return
	end

	def mobile_activate
		activate_info = {"mobile" => params[:mobile],
				"password" => params[:password],
				"verification_code" => params[:verification_code]}
		retval = User.activate("mobile", activate_info, @remote_ip, params[:_client_type])
		render_json_auto(retval) and return
	end

	def registered_user_exist
		u = User.find_by_email_mobile(params[:email_mobile])
		render_json_auto({"exist" => (u &&  u.is_activated)}) and return
	end
end
