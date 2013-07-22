# coding: utf-8
require 'error_enum'
require 'quill_common'
class Sample::AccountsController < ApplicationController
	before_filter :require_sign_in

	def get_basic_info
		# answer number, spread number, third party accounts
		@answer_number = @current_user.answers.not_preview.finished.length
		@spread_number = Answer.where(:introducer_id => @current_user._id).not_preview.finished.length
		@third_party_bind_info = {}
		["sina", "renren", "qq", "google", "kaixin001", "douban", "baidu", "sohu", "qihu360"].each do |website|
			@third_party_bind_info[website] = !@current_user.third_party_users.where(:website => website).blank?
		end
		@completed_info = @current_user.completed_info
		@basic_info = {
			"answer_number" => @answer_number,
			"spread_number" => @spread_number,
			"third_party_bind_info" => @third_party_bind_info,
			"completed_info" => @completed_info
		}
		render_json_auto @basic_info and return
	end

	def get_basic_attributes
		user = User.find_by_id(params[:id]) if params[:id]
		user = @current_user if user.nil?
		render_json_auto(user) and return
	end

	def set_basic_attributes
		retval = @current_user.set_basic_info(params[:basic_attributes])
		render_json_auto(retval) and return   	
	end

	def get_receiver_info
		receiver_info = @current_user.affiliated.receive_info
		render_json_auto(receiver_info) and return
	end

	def set_receiver_info
		retval = @current_user.update_receive_info(params[:receive_info])
		render_json_auto(retval) and return     
	end

	def reset_password
		retval = @current_user.reset_password(params[:old_password], params[:new_password])
		render_json_auto(retval) and return
	end
end