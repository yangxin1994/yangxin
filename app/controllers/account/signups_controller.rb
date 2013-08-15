class Account::SignupsController < ApplicationController

  before_filter :require_sign_out

  # PAGE
  def show
  	@signin_btn = true
  	
  	case application_name
  	when 'quillme'
  		@hide_right = true
			render :template => 'account/signups/show_quillme', :layout => 'quillme'
		else
			render :template => 'account/signups/show_quill', :layout => 'sign'
		end
  end

  # AJAX
	def create
	  render :json => Account::RegistrationClient.new(session_info).register(
	    params[:email], params[:password], params[:password_confirmation], 
	    params[:introducer_id], "#{request.protocol}#{request.host_with_port}/activate", 
	    params[:third_party_user_id])
	end
	
end
