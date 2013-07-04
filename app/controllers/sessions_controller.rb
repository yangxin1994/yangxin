# encoding: utf-8
require 'encryption'
require 'error_enum'
require 'tool'
class SessionsController < ApplicationController

	before_filter :require_sign_in, :only => [:destroy]

	def create
		login = User.login_with_email_mobile(params[:email_mobile], params[:password], @remote_ip, params[:_client_type], params[:keep_signed_in], params[:third_party_user_id])
		render_json_auto(login) and return
	end

	def destroy
		User.logout(params[:auth_key])
		render_json_s and return
	end

	def login_with_auth_key
		retval = User.login_with_auth_key(params[:auth_key])
		render_json_auto(retval) and return
	end
	
	def third_party_sign_in
		response_data = ThirdPartyUser.get_access_token(params[:website], params[:code], params[:redirect_uri])
		tp_user = ThirdPartyUser.find_or_create_user(params[:website], response_data)
		render_json_e(tp_user) and return if tp_user == ErrorEnum::WRONG_THIRD_PARTY_WEBSITE
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
