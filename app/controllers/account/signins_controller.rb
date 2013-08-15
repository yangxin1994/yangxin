class Account::SigninsController < ApplicationController
  
  # PAGE: show sign in
  def show
  	case application_name
  	when 'quillme'
  		redirect_to after_sign_in_account_path({ref: params[:ref]}) and return if user_signed_in
  		# redirect_to (params[:ref].blank? ? root_path : params[:ref]) and return if user_signed_in
  		@hide_right = true
			render :template => 'account/signins/show_quillme', :layout => 'quillme'
		else
  		redirect_to after_sign_in_account_path({ref: params[:ref]}) and return if user_signed_in
      if params[:m].try 'to_b'
        render :template => 'account/signins/show_quill', :formats => 'mobile', :layout => 'app'
      else
        render :template => 'account/signins/show_quill', :layout => 'sign'
      end
		end
  end

  # AJAX: sign in
  def create
    result = User.login_with_email_mobile(params[:email],
                                          params[:password], 
                                          @remote_ip, 
                                          params[:_client_type], 
                                          params[:permanent_signed_in], 
                                          params[:third_party_user_id])
		refresh_session(result['auth_key'])
    binding.pry
    
  	render :json => result
  end
  
end
