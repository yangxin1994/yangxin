# encoding: utf-8
require 'encryption'
class SurveyMailer < ActionMailer::Base
	layout 'email'

	default from: "\"优数调研\" <postmaster@oopsdata.net>", charset: "UTF-8"

	@@test_email = "test@oopsdata.com"

	self.smtp_settings = {
		:authentication => "plain",
		:address        => "smtp.mailgun.com",
		:port           => 25,
		:domain         => "oopsdata.net",
		:user_name      => "postmaster@oopsdata.net",
		:password       => "0nlnhy08vbk1",
		:enable_starttls_auto => true,
		:openssl_verify_mode  => 'none'
	}

	def survey_email(user_id, survey_id_ary)
		# set_custom_smtp_setting
		@user = User.find_by_id(user_id)
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
		email = Rails.env == "production" ? @user.email : @@test_email
		subject = "邀请您参加问卷调查"
		subject += " --- to #{@user.email}" if Rails.env != "production"
		mail(:to => email, :subject => subject)
	end

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

=begin
	def set_custom_smtp_setting
		@_temp_smtp_settings = @@smtp_settings
		@@smtp_settings = Rails.application.config.survey_mailer_setting
	end

	def deliver!(mail = @mail)
		out = super
		if @_temp_smtp_settings
			@@smtp_settings = @_temp_smtp_settings
			@_temp_smtp_settings = nil
		end
		out
	end
=end

	def remove_bounce_emails
		limit = 1000
		skip = 0
		loop do
			retval = Tool.send_get_request("https://api.mailgun.net/v2/oopsdata.net/bounces?limit=#{limit}&skip=#{skip}",
				true,
				"api",
				Rails.application.config.mailgun_api_key)
			bounced_emails = retval.body["items"]
			break if bounced_emails.blank?
			bounced_emails.each do |email|
				address = email["address"]
				ImportEmail.destroy_by_email(address)
			end
			skip += limit
		end
	end
end
