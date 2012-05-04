# encoding: utf-8
require 'error_enum'
class UsersController < ApplicationController

	before_filter :require_sign_in

	#*descryption*: update profile of a signed in user
	#
	#*http* *method*: post
	#
	#*url*: /update_information
	#
	#*params*:
	#* user_information: a hash that has the following keys
	#  - email
	#  - realname
	#  - address
	#  - zipcode
	#  - telephone
	#  - gender
	#  - marriage
	#  - education
	#  - birthday
	#  - location
	#  - family_incoming
	#  - personal_incoming
	#  - position
	#  - industry
	#
	#*retval*:
	#* true if succeed
	def update_information
		@current_user.update_information(params[:user_information])
		respond_to do |format|
			format.json	{ render :json => true and return }
		end
	end

	#*descryption*: user resets the new password
	#
	#*http* *method*: post
	#
	#*url*: /reset_password
	#
	#*params*:
	#* old_password
	#* new_password
	#
	#*retval*:
	#* true if succeed
	#* ErrorEnum ::WRONG_PASSWORD 
	def reset_password
		reset_password_retval = @current_user.reset_password(params["old_password"], params["new_password"])
		case reset_password_retval
		when ErrorEnum::WRONG_PASSWORD
			flash[:notice] = "密码错误"
			respond_to do |format|
				format.html { redirect_to reset_password_path and return }
				format.json { render :json => ErrorEnum::WRONG_PASSWORD and return }
			end
		else
			flash[:notice] = "密码已重置"
			respond_to do |format|
				format.html { redirect_to home_path and return }
				format.json { render :json => true and return }
			end
		end
	end
end
