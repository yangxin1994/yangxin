# encoding: utf-8
require 'error_enum'
require 'tool'
class SurveySubscribe
	include Mongoid::Document
	include Mongoid::ValidationsExt

  EmailRexg  = '\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z'
  MobileRexg = '^(13[0-9]|15[0|1|2|3|6|7|8|9]|18[8|9])\d{8}$' 
	field :subscribe_channel, :type => String, default: nil
  field :active, :type => Boolean, default: false
  field :active_code, :type => String, default: nil

	belongs_to :user

	before_create :generate_active_code

  def make_active
    self.update_attributes(:active => true)
  end

  def self.activate(active_info)
    code  = active_info['code']
    email = active_info['email']
    time  = active_info['time']   
    ss    = SurveySubscribe.where(:subscribe_channel => email).first
    return ErrorEnum::USER_NOT_EXIST if !ss.present?
    return ErrorEnum::ACTIVATE_EXPIRED if Time.now.to_i - time.to_i > OOPSDATA[RailsEnv.get_rails_env]["activate_expiration_time"].to_i        
    user = User.find_by_email(email)
    if user.present?
      ss.update_attributes(:user_id => user.id)
    end
    ss.make_active
    return {:success => true}
  end

  def active?
    return self.active
  end
  
	def generate_active_code
    if self.subscribe_channel.match(/#{EmailRexg}/i)
      self.active_code = Tool.generate_active_email_token
    elsif self.subscribe_channel.match(/#{MobileRexg}/)
      self.active_code = Tool.generate_active_mobile_code
    end

	end

  def re_generate_code
    if self.subscribe_channel.match(/#{EmailRexg}/i)
      self.update_attributes(:active_code => Tool.generate_active_email_token)  
    else
      self.update_attributes(:active_code => Tool.generate_active_mobile_code)
    end
  end

  def send_active_link_or_code(callback)
    if self.subscribe_channel.match(/#{EmailRexg}/i)
      SurveySubscribeWorker.perform_async(self.subscribe_channel,callback)
    else
      # send moile message
    end
  end

end
