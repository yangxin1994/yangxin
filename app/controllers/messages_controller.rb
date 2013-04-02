require 'error_enum'
class MessagesController < ApplicationController
	
  before_filter :require_sign_in

  def index
    @messages = auto_paginate current_user.show_messages
    render_json { @messages }
  end
  
  def unread_count
    render_json { current_user.unread_messages_count }
  end 

end
