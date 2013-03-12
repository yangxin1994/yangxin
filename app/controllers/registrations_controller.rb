# encoding: utf-8
require 'error_enum'
require 'tool'
require 'encryption'

class RegistrationsController < ApplicationController

	before_filter :require_sign_out, :except => [:email_illegal, :destroy]

	#*descryption*: user submits registration form
	#
	#*http* *method*: post
	#
	#*url*: /registrations
	#
	#*params*:
	#* user: the user hash, the keys of which include:
	#  - email
	#  - username
	#  - password
	#  - password_confirmation
	#* third_party_user_id: a key if user registrates with a third party website account
	#
	#*retval*:
	#* true if successfully registrated
	#* ErrorEnum ::ILLEGAL_EMAIL
	#* ErrorEnum ::EMAIL_ACTIVATED
	#* ErrorEnum ::EMAIL_NOT_ACTIVATED
	#* ErrorEnum ::WRONG_PASSWORD_CONFIRMATION
	def create
		# create user model
		retval = User.create_new_registered_user(params[:user],
												@current_user,
												params[:third_party_user_id],
												params[:callback])
		render_json_auto(retval) and return
	end

	#*description*: submit email address to send activate email
	#
	#*http* *method*: post
	#
	#*url*: /send_activate_email
	#
	#*params*:
	#* email
	#
	#*retval*:
	#* true if the activate email is sent out
	#* Errorenum ::USER_NOT_EXIST
	#* Errorenum ::USER_ACTIVATED
	def send_activate_email
		user = User.find_by_email(params[:email])
		render_json_e(ErrorEnum::USER_NOT_EXIST) and return if user.nil?
		render_json_e(ErrorEnum::USER_ACTIVATED) and return if user.is_activated
		EmailWorker.perform_async("activate", user.email, params[:callback])
		render_json_s and return
	end

	#*description*: click activate link to activate an user
	#
	#*http* *method*: get
	#
	#*url*: /activate
	#
	#*params*:
	#* activate_key
	#
	#*retval*:
	def activate
		begin
			activate_info_json = Encryption.decrypt_activate_key(params[:activate_key])
			activate_info = JSON.parse(activate_info_json)
		rescue
			render_json_e(ErrorEnum::ILLEGAL_ACTIVATE_KEY) and return
		end
		retval = User.activate(activate_info, @remote_ip, params[:_client_type])
		render_json_auto(retval) and return
	end

	# delete account
	def destroy
		retval = @current_user.destroy
		render_json_auto(retval) and return
	end
end
