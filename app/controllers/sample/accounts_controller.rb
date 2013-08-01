 # coding: utf-8
require 'error_enum'
require 'quill_common'
class Sample::AccountsController < ApplicationController
	before_filter :require_sign_in

	def get_basic_info
		# answer number, spread number, third party accounts
		@answer_number = @current_user.answers.not_preview.finished.length
		@spread_number = Answer.where(:introducer_id => @current_user._id).not_preview.finished.length
		@bind_info = {}
		["sina", "renren", "qq", "google", "kaixin001", "douban", "baidu", "sohu", "qihu360"].each do |website|
			@bind_info[website] = !ThirdPartyUser.where(:user_id => @current_user._id.to_s, :website => website).blank?
		end
		@bind_info["email"] = @current_user.email_activation
		@bind_info["mobile"] = @current_user.mobile_activation

		@completed_info = @current_user.completed_info
		
		@basic_info = {
			"answer_number" => @answer_number,
			"spread_number" => @spread_number,
			"bind_info" => @bind_info,
			"completed_info" => @completed_info,
			"point" => @current_user.point,
			"sample_id" => @current_user._id.to_s,
			"nickname" => @current_user.nickname
		}

		render_json_auto @basic_info and return
	end

	def get_basic_attributes
		render_json_auto(@current_user.get_basic_attributes) and return
	end

	def set_basic_attributes
		retval = @current_user.set_basic_attributes(params[:basic_attributes])
		render_json_auto(retval) and return   	
	end

	def get_receiver_info
		receiver_info = @current_user.affiliated.try(:receiver_info) || {}
		render_json_auto(receiver_info) and return
	end

	def set_receiver_info
		retval = @current_user.set_receiver_info(params[:receiver_info])
		render_json_auto(retval) and return
	end

	def reset_password
		retval = @current_user.reset_password(params[:old_password], params[:new_password])
		render_json_auto(retval) and return
	end

	def get_bind_info
		@bind_info = {}
		if @current_user.email_activation
			@bind_info["email"] = [@current_user.email, @current_user.email_subscribe]
		end
		if @current_user.mobile_activation
			@bind_info["mobile"] = [@current_user.mobile, @current_user.mobile_subscribe]
		end
		["sina", "renren", "qq", "google", "kaixin001", "douban", "baidu", "sohu", "qihu360"].each do |website|
			third_party_user = ThirdPartyUser.where(:user_id => @current_user._id.to_s, :website => website).first
			@bind_info[website] = [third_party_user.name, third_party_user.share] if !third_party_user.nil?
		end
		render_json_auto @bind_info and return
	end

	def unbind
		third_party_user = ThirdPartyUser.where(:website => params[:website], :user_id => @current_user._id.to_s).first
		third_party_user.destroy if !third_party_user.nil?
		render_json_auto true and return
	end

	def set_share
		third_party_user = ThirdPartyUser.where(:website => params[:website], :user_id => @current_user._id.to_s).first
		render_json_e ErrorEnum::THIRD_PARTY_USER_NOT_EXIST and return if third_party_user.nil?
		third_party_user.share = params[:share] == "true"
		third_party_user.save
		render_json_auto true and return
	end

	def set_subscribe
		if params[:type] == "email"
			@current_user.email_subscribe = params[:subscribe].to_s == "true" if @current_user.email_activation
		else
			@current_user.mobile_subscribe = params[:subscribe].to_s == "true" if @current_user.mobile_activation
		end
		render_json_auto @current_user.save and return
	end

	def messages
		@messages = @current_user.messages
		@paginated_messages = auto_paginate @messages do |paginated_messages|
			paginated_messages.map { |e| e.info_for_sample }
		end
		render_json_auto @paginated_messages and return
	end

	def destroy_message
		@message = Message.find_by_id(params[:message_id])
		render_json_e ErrorEnum::MESSAGE_NOT_EXIST and return if !@current_user.messages.include?(@message)
		render_json_auto @message.destroy and return
	end

	def destroy_all_messages
		render_json_auto @current_user.messages.destroy_all and return
	end

	def send_change_email
		render_json_e ErrorEnum::EMAIL_OR_MOBILE_EXIST if !User.find_by_email(params[:email]).nil?
		@current_user.email_to_be_changed = params[:email]
		@current_user.change_email_expiration_time = Time.now.to_i + OOPSDATA[RailsEnv.get_rails_env]["activate_expiration_time"].to_i
		@current_user.save
		EmailWorker.perform_async("change_email", params[:email], params[:callback])
		render_json_s and return
	end

	def send_change_sms
		render_json_e ErrorEnum::EMAIL_OR_MOBILE_EXIST if !User.find_by_email(params[:mobile]).nil?
		@current_user.mobile_to_be_changed = params[:mobile]
		# @current_user.sms_verification_code = Random.rand(100000..999999).to_s
		@current_user.sms_verification_code = "111111"
		@current_user.sms_verification_expiration_time = Time.now.to_i + OOPSDATA[RailsEnv.get_rails_env]["activate_expiration_time"].to_i
		@current_user.save
		## todo: send message to the mobile
		render_json_s and return
	end

	def change_email
		begin
			activate_info_json = Encryption.decrypt_activate_key(params[:activate_key])
			activate_info = JSON.parse(activate_info_json)
		rescue
			render_json_e(ErrorEnum::ILLEGAL_ACTIVATE_KEY) and return
		end
		render_json_e ErrorEnum::EMAIL_NOT_EXIST and return if @current_user.email_to_be_changed != activate_info["email"]
		render_json_e ErrorEnum::ACTIVATE_EXPIRED if @current_user.change_email_expiration_time < Time.now.to_i
		@current_user.email = @current_user.email_to_be_changed
		render_json_auto @current_user.save and return
	end

	def change_mobile
		render_json_e ErrorEnum::MOBILE_NOT_EXIST and return if @current_user.mobile_to_be_changed != params[:mobile]
		render_json_e ErrorEnum::ILLEGAL_ACTIVATE_KEY and return if @current_user.sms_verification_code != params[:verification_code]
		render_json_e ErrorEnum::ACTIVATE_EXPIRED if @current_user.sms_verification_expiration_time < Time.now.to_i
		@current_user.mobile = @current_user.mobile_to_be_changed
		render_json_auto @current_user.save and return
	end
end