class Account::MessagesController < ApplicationController
  
  before_filter :require_sign_in

  # Page: list messages
  def index
    @is_account_mgr = true
		params[:page] = params[:pi]
		params[:per_page] = params[:ps]
		@messages = auto_paginate current_user.show_messages
		
		render :template => 'account/messages/index_quill', :layout => 'quill'

  end
  
end