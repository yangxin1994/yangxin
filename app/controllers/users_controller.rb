require 'error_enum'
class UsersController < ApplicationController

	before_filter :require_sign_in

	def get_level_information
		retval = @current_user.get_level_information
		respond_to do |format|
			format.json { render_json_auto(retval) and return }
		end
	end

	def get_basic_info
		user = User.find_by_id(params[:id]) if params[:id]
		user = @current_user if user.nil?
		render_json_auto(user) and return
	end

	def get_email
		@user = User.find_by_id_including_deleted(params[:id])
		render_json_auto(ErrorEnum::USER_NOT_EXIST) and return if @user.nil?
		render_json_auto @user.email
	end

	def point
		render_json { @current_user.point ? @current_user.point : 0 }
	end
	
	def lottery_codes
		render_json {auto_paginate(@current_user.lottery_codes)}
	end	

	def get_introduced_users
		introduced_users = auto_paginate @current_user.get_introduced_users do |u|
			u.slice((page - 1) * per_page, per_page)
		end
		render_json_auto(introduced_users) and return
	end
end
