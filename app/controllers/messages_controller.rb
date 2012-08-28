# encoding: utf-8
require 'error_enum'
class MessagesController < ApplicationController
 
  def index
    @messages = current_user.show_messages
    @messages = ErrorEnum::MESSAGE_NOT_FOUND if @messages.empty? 
    #todo 更新 last_read_time
    respond_to do |format|
      format.json { render :json => @messages }
    end
  end
  def unread_count
    respond_to do |format|
      format.json { render :json => current_user.unread_messages_count }
    end
  end 
end