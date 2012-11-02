require 'error_enum'
class MessagesController < ApplicationController
	
  before_filter :require_sign_in

  def index
    @messages = current_user.show_messages.slice(current_page, per_page)
    #@messages = ErrorEnum::MESSAGE_NOT_FOUND if @messages.empty? 
    respond_and_render_json { @messages }
  end

  def unread_count
    respond_and_render_json { current_user.unread_messages_count }
  end 
  private
  def current_page
    (page - 1) * per_page
  end
end