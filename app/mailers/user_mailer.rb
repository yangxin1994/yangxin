# encoding: utf-8
require 'encryption'
class UserMailer < ActionMailer::Base
#  default from: "no-reply@oopsdata.com"
  default from: "oopsdata2012@gmail.com"

	def welcome_email(user)
		@user = user
		activate_info = {"email" => user.email, "time" => Time.now.to_i}
		@activate_link = "http://" + OOPSDATA[RailsEnv.get_rails_env]["root_url"] + "/activate?activate_key=" + CGI::escape(Encryption.encrypt_activate_key(activate_info.to_json))
		mail(:to => user.email, 
					:subject => "欢迎注册Oops!Data",
					:content_type => "text/html; charset=utf-8")
	end

	def activate_email(user)
		@user = user
		activate_info = {"email" => user.email, "time" => Time.now.to_i}
		@activate_link = "http://" + OOPSDATA[RailsEnv.get_rails_env]["root_url"] + "/activate?activate_key=" + CGI::escape(Encryption.encrypt_activate_key(activate_info.to_json))
		mail(:to => user.email, 
					:subject => "激活Oops!Data",
					:content_type => "text/html; charset=utf-8")
	end
	
	def password_email(user)
		@user = user
		password_info = {"email" => user.email, "time" => Time.now.to_i}
		@password_link = "http://" + OOPSDATA[RailsEnv.get_rails_env]["root_url"] + "/reset_password?password_key=" + CGI::escape(Encryption.encrypt_activate_key(password_info.to_json))
		mail(:to => user.email, 
					:subject => "重置Oops!Data密码",
					:content_type => "text/html; charset=utf-8")
	end
	
	def publish_email(publish_status_history)
		@survey = Survey.find_by_id(publish_status_history.survey_id)
		@user = User.find_by_email(@survey.owner_email)
		@message = publish_status_history.message
		mail(:to => @user.email, 
					:subject => "您的点查问卷 #{@survey.title} 已经发布",
					:content_type => "text/html; charset=utf-8")
	end
	
	def reject_email(publish_status_history)
		@survey = Survey.find_by_id(publish_status_history.survey_id)
		@user = User.find_by_email(@survey.owner_email)
		@message = publish_status_history.message
		mail(:to => @user.email, 
					:subject => "您的点查问卷 #{@survey.title} 被拒绝发布",
					:content_type => "text/html; charset=utf-8")
	end
end
