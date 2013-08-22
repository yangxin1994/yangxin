class Account::MessagesController < ApplicationController
  
  before_filter :require_sign_in

  # Page: list messages
	def index
		@is_account_mgr = true

		params[:page] = params[:pi]
		params[:per_page] = params[:ps]
		@messages = auto_paginate current_user.show_messages
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