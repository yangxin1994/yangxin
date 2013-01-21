# encoding: utf-8
require 'encryption'
class UserMailer < ActionMailer::Base
	layout 'email'

  default from: "postmaster@oopsdata.net", charset: "UTF-8"

	def welcome_email(user, callback)
		@user = user
		activate_info = {"email" => user.email, "time" => Time.now.to_i}
		@activate_link = "#{callback}?key=" + CGI::escape(Encryption.encrypt_activate_key(activate_info.to_json))
		mail(:to => user.email, :subject => "欢迎注册优数调研")
	end

	def activate_email(user, callback)
		@user = user
		activate_info = {"email" => user.email, "time" => Time.now.to_i}
		@activate_link = "#{callback}?key=" + CGI::escape(Encryption.encrypt_activate_key(activate_info.to_json))
		mail(:to => user.email, :subject => "激活优数调研账户")
	end
	
	def password_email(user, callback)
		@user = user
		password_info = {"email" => user.email, "time" => Time.now.to_i}
		@password_link = "#{callback}?key=" + CGI::escape(Encryption.encrypt_activate_key(password_info.to_json))
		mail(:to => user.email, :subject => "重置优数调研密码")
	end
	
	def lottery_code_email(user, survey_id, lottery_code, callback)
		@user = user
		@survey = Survey.find_by_id(survey_id)
		@lottery_code = lottery_code
		@callback = callback
		mail(:to => user.email, :subject => "重置优数调研密码")
	end

	def survey_email(user_id, survey_id_ary)
		@user = User.find_by_id(user_id)
		@surveys = survey_id_ary.map { |e| Survey.find_by_id(e) }
		@surveys.each do |s|
			email_history = EmailHistory.create
			email_history.user = @user
			email_history.survey = s
		end
		mail(:to => user.email, :subject => "邀请您参加问卷调查")
	end
	
	def publish_email(publish_status_history)
		@survey = Survey.find_by_id(publish_status_history.survey_id)
		@user = User.find_by_email(@survey.owner_email)
		@message = publish_status_history.message
		@url = "#{Rails.application.config.quill_host}/questionaires/#{@survey._id.to_s}/share"
		mail(:to => @user.email, :subject => "您的调查问卷 #{@survey.title} 已经发布")
	end
	
	def reject_email(publish_status_history)
		@survey = Survey.find_by_id(publish_status_history.survey_id)
		@user = @survey.user
		@message = publish_status_history.message
		@url = "#{Rails.application.config.quill_host}/questionaires/#{@survey._id.to_s}"
		mail(:to => @user.email, :subject => "您的调查问卷 #{@survey.title} 发布申请被拒绝")
	end
end
