# encoding: utf-8
require 'encryption'
class UserMailer < ActionMailer::Base
	layout 'email'

	default from: "\"优数调研\" <postmaster@oopsdata.net>", charset: "UTF-8"

	@@test_email = "test@oopsdata.com"

	def welcome_email(user, callback)
		@user = user
		activate_info = {"email" => user.email, "time" => Time.now.to_i}
		@activate_link = "#{callback}?key=" + CGI::escape(Encryption.encrypt_activate_key(activate_info.to_json))
		email = Rails.env == "production" ? user.email : @@test_email
		subject = "欢迎注册优数调研"
		subject += " --- to #{user.email}" if Rails.env != "production"
		mail(:to => email, :subject => subject)
	end

	def activate_email(user, callback)
		@user = user
		activate_info = {"email" => user.email, "time" => Time.now.to_i}
		@activate_link = "#{callback}?key=" + CGI::escape(Encryption.encrypt_activate_key(activate_info.to_json))
		email = Rails.env == "production" ? user.email : @@test_email
		subject = "激活账户"
		subject += " --- to #{user.email}" if Rails.env != "production"
		mail(:to => email, :subject => subject)
	end
	
	def password_email(user, callback)
		@user = user
		password_info = {"email" => user.email, "time" => Time.now.to_i}
		@password_link = "#{callback}?key=" + CGI::escape(Encryption.encrypt_activate_key(password_info.to_json))
		email = Rails.env == "production" ? user.email : @@test_email
		subject = "重置密码"
		subject += " --- to #{user.email}" if Rails.env != "production"
		mail(:to => email, :subject => subject)
	end
	
	def lottery_code_email(user, survey_id, lottery_code_id, callback)
		@user = user
		@survey = Survey.find_by_id(survey_id)
		@lottery_code = LotteryCode.where(:_id => lottery_code_id).first
		lottery = @lottery_code.try(:lottery)
		@survey_list_url = "#{Rails.application.config.quillme_host}/surveys"
		@lottery_url = "#{Rails.application.config.quillme_host}/lotteries/#{lottery.try(:_id)}"
		@lottery_title = lottery.try(:title)
		@lottery_code_url = "#{Rails.application.config.quillme_host}/lotteries/own"
		email = Rails.env == "production" ? user.email : @@test_email
		subject = "恭喜您获得抽奖号"
		subject += " --- to #{user.email}" if Rails.env != "production"
		mail(:to => email, :subject => subject)
	end
end
