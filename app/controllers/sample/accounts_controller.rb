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
		retval = @current_user.set_basic_info(params[:basic_attributes])
		render_json_auto(retval) and return   	
	end

	def get_receiver_info
		receiver_info = @current_user.affiliated.receiver_info
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
		if @current_user.email_activation?
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
end