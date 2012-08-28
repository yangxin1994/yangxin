# encoding: utf-8
require 'error_enum'
class MessagesController < ApplicationController
  before_filter :require_sign_in
  def index
    @messages = current_user.show_messages
    #@messages = ErrorEnum::MESSAGE_NOT_FOUND if @messages.empty? 
    #todo 更新 last_read_time
    respond_and_render_json { @messages }
  end
  def unread_count
      respond_and_render_json { current_user.unread_messages_count }
  end 
end