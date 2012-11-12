# encoding: utf-8
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
		respond_to do |format|
		format.json { render_json_auto(user) and return }
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
end
