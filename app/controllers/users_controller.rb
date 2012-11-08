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

	def get_invited_user_ids
		invited_user_ids = @current_user.get_invited_user_ids
		render_json_auto(invited_user_ids) and return
	end
end
