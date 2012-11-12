require 'error_enum'
class UsersController < ApplicationController

	before_filter :require_sign_in

	def get_level_information
		retval = @current_user.get_level_information
		respond_to do |format|
			format.json { render_json_auto(retval) and return }
		end
	end

	def get_invited_user_ids
		invited_user_ids = @current_user.get_invited_user_ids
		render_json_auto(invited_user_ids) and return
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
end
