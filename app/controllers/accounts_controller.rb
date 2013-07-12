# coding: utf-8
require 'error_enum'
require 'quill_common'
class AccountsController < ApplicationController

  def get_basic_info
    user = User.find_by_id(params[:id]) if params[:id]
    user = @current_user if user.nil?
    render_json_auto(user) and return
  end

  def get_spread_count
    @spread_count = Answer.where(:introducer_id => @current_user.id).count   
    render_json_auto(@spread_count) and return
  end

  def get_answer_count
    @answer_count = @current_user.answers.count
    render_json_auto(@answer_count) and return
  end


  def update_avatar
    retval = @current_user.update_avatar(params[:avatar])
    render_json_auto(retval) and return    
  end

  def get_receive_info
    receiver_info = @current_user.affiliated
    render_json_auto(receiver_info) and return
  end

  def update_receive_info
    retval = @current_user.update_receive_info(params[:receive_info])
    render_json_auto(retval) and return     
  end


  def update_basic_info
    retval = @current_user.update_basic_info(params[:receive_info])
    render_json_auto(retval) and return   	
  end

  def reset_password
    retval = @current_user.reset_password(params[:old_password], params[:new_password], params[:new_password_confirmation])
    render_json_auto(retval) and return
  end  	
end