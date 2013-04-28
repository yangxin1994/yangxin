# encoding: utf-8
require 'encryption'
class TestMailer < ActionMailer::Base
	default from: "\"优数调研\" <postmaster@oopsdata.net>", charset: "UTF-8"

	self.smtp_settings = Rails.application.config.survey_mailer_setting

	def test_email
		mail(:to => "jesse.yang1985@gmail.com", :subject => subject)
	end
end
