# encoding: utf-8
require 'array'
require 'error_enum'
require 'quill_common'
class Sample::SurveySubscribesController < ApplicationController

  def subscribe_able
    channel = params[:subscribe_channel]
    if channel.present? && (channel.match(/#{SurveySubscribe::EmailRexg}/) || channel.match(/#{SurveySubscribe::MobileRexg}/)) 
      @ss = SurveySubscribe.where(:subscribe_channel => "#{channel}").first
      if @ss.present? && !@ss.active?
        #已经申请但未激活的申请,重新生成code
        @ss.re_generate_code
        @ss.send_active_link_or_code(params[:callback])
      end
      
      if !@ss.present?
        @ss = SurveySubscribe.create(:subscribe_channel => channel)
        if (current_user.present? && (current_user.email == channel || current_user.mobile == channel))
          @ss.update_attriutes(:user_id => current_user.id,:active => true)
        elsif (current_user.present? && current_user.email != channel && current_user.mobile != channel)
          @ss.send_active_link_or_code(params[:callback])
        elsif  !current_user.present?
          user = User.where(:email => "#{channel}").first
          user = User.where(:mobile => "#{channel}").first
          if user.present?
            @ss.update_attriutes(:user_id => user.id)
          end 
          @ss.send_active_link_or_code(params[:callback])
        end 
      end
      render_json_s and return 
    else
      render_json_e and return 
    end
  end


  def make_subscribe_active

    begin
      activate_info_json = Encryption.decrypt_activate_key(CGI::unescape(params[:key]))
      activate_info = JSON.parse(activate_info_json)
    rescue
      render_json_e(ErrorEnum::ILLEGAL_ACTIVATE_KEY) and return
    end

    retval = SurveySubscribe.activate(activate_info)
    render_json_auto(retval) and return    
  end


end
