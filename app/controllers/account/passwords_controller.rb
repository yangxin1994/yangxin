class Account::PasswordsController < ApplicationController

  before_filter :require_sign_out, :except => []

	# PAGE
	def find
  	@signin_btn = true
  	
  	case application_name
  	when 'quillme'
  		@hide_right = true
			render :template => 'account/passwords/find_quillme', :layout => 'quillme'
		else
			render :template => 'account/passwords/find_quill', :layout => 'sign'
		end
	end

	# AJAX
	def send_reset_email
		render :json => Account::SessionClient.new(session_info).send_reset_password_email(
			params[:email], "#{request.protocol}#{request.host_with_port}/password/reset")
	end

	# PAGE
	def reset
  	@signin_btn = true
  	
  	case application_name
  	when 'quillme'
  		@hide_right = true
			render :template => 'account/passwords/reset_quillme', :layout => 'quillme'
		else
			render :template => 'account/passwords/reset_quill', :layout => 'sign'
		end
	end

	# AJAX
	def update
		render :json => Account::SessionClient.new(session_info).new_password(
			params[:key], params[:password], params[:password_confirmation])
	end

end