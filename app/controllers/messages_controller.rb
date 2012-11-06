require 'error_enum'
class MessagesController < ApplicationController
	
  before_filter :require_sign_in

  def index
    @messages = {}
    m = current_user.show_messages
    @messages["data"] = m.slice((page - 1) * per_page, per_page)
    @messages["current_page"] = page
    @messages["per_page"] = per_page
    @messages["total_page"] = (m.size / per_page.to_f ).ceil
    #@messages = ErrorEnum::MESSAGE_NOT_FOUND if @messages.empty? 
    respond_and_render_json { @messages }
  end
  
  def unread_count
    respond_and_render_json { current_user.unread_messages_count }
  end 

end