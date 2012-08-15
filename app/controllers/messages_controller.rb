# encoding: utf-8
require 'error_enum'
class MessagesController < ApplicationController
 
  def index
    @messages = current_user.show_messages
    @messages = ErrorEnum::MessgaeNotFound if @messages.empty? 
    respond_to do |format|
      format.json { render json: @messages }
    end
  end
 
end