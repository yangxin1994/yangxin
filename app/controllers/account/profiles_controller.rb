class Account::ProfilesController < ApplicationController
	
	before_filter :require_sign_in, :except => [:find_password]

	# AJAX
	def reset_password
		return :json => Account::UserClient.new(session_info).reset_password(param[:email])
	end
	
	# PAGE: show profile
	def show
		@is_account_mgr = true
		@common_user = Account::UserClient.new(session_info).get_basic_info
  	case application_name
  	when 'quillme'
  		@hide_right = true
			render :template => 'account/profiles/show_quillme', :layout => 'quillme'
		else
			render :template => 'account/profiles/show_quill', :layout => 'quill'
		end
	end

	# AJAX
	def update
		client = Account::UserClient.new(session_info)
		common_user = client.get_basic_info.value
		render :json => client.update_basic_info(
			params[:full_name], params[:identity_card], params[:company].nil? ? common_user['company'] : params[:company], 
			params[:address], params[:phone])
	end

	# AJAX
	def update_password
		render :json => Account::UserClient.new(session_info).reset_password(params[:old_password], 
						params[:new_password], params[:new_password_confirmation])
	end

end