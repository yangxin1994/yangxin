# encoding: utf-8
require 'encryption'
class TempFourMailer < ActionMailer::Base
	layout 'email'

	default from: "\"优数调研\" <postmaster@four.mailgun.org>", charset: "UTF-8"

	@@test_email = "test@oopsdata.com"

	self.smtp_settings =
	{
		:authentication => "plain",
		:address        => "smtp.mailgun.com",
		:port           => 25,
		:domain         => "four.mailgun.org",
		:user_name      => "postmaster@four.mailgun.org",
		:password       => "8wx9ctwr3412",
		:enable_starttls_auto => true,
		:openssl_verify_mode  => 'none'
	}

	def imported_email_survey_email(user_email, survey_id_ary)
		# set_custom_smtp_setting
		@surveys = survey_id_ary.map { |e| Survey.find_by_id(e) }
		@presents = []	
		# push a lottery
		lottery = Lottery.quillme.first
		@presents << {:title => lottery.title,
			:url => "#{Rails.application.config.quillme_host}/lotteries/#{lottery._id.to_s}",
			:img_url => Rails.application.config.quillme_host + lottery.photo_url} if !lottery.nil?
		# push a real gift
		real_gift = BasicGift.where(:type => 1, :status => 1).first
		@presents << {:title => real_gift.name,
			:url => "#{Rails.application.config.quillme_host}/gifts/#{real_gift._id.to_s}",
			:img_url => Rails.application.config.quillme_host + real_gift.photo.picture_url} if !real_gift.nil?
		# push a cash gift
		cash_gift = BasicGift.where(:type => 0, :status => 1).first
		@presents << {:title => cash_gift.name,
			:url => "#{Rails.application.config.quillme_host}/gifts/#{cash_gift._id.to_s}",
			:img_url => Rails.application.config.quillme_host + cash_gift.photo.picture_url} if !cash_gift.nil?
		email = Rails.env == "production" ? user_email : @@test_email
		subject = "邀请您参加问卷调查"
		subject += " --- to #{user_email}" if Rails.env != "production"
		mail(:to => email, :subject => subject)
	end
end
