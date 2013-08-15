class Account::MessagesController < ApplicationController
  
  before_filter :require_sign_in

  # Page: list messages
	def index
		@is_account_mgr = true

		@messages = nil
		result = Account::MessageClient.new(session_info).get_messages(
			params[:pi].to_i, params[:ps].to_i)
		if(result.success)
			@messages = result.value
		end

		session[:unread_message_count] = 0

  	case application_name
  	when 'quillme'
  		@hide_right = true
			render :template => 'account/messages/index_quillme', :layout => 'quillme'
		else
			render :template => 'account/messages/index_quill', :layout => 'quill'
		end

	end
	
end