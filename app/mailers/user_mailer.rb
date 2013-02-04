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
		mail(:to => email, :subject => "欢迎注册优数调研")
	end

	def activate_email(user, callback)
		@user = user
		activate_info = {"email" => user.email, "time" => Time.now.to_i}
		@activate_link = "#{callback}?key=" + CGI::escape(Encryption.encrypt_activate_key(activate_info.to_json))
		email = Rails.env == "production" ? user.email : @@test_email
		mail(:to => email, :subject => "激活账户")
	end
	
	def password_email(user, callback)
		@user = user
		password_info = {"email" => user.email, "time" => Time.now.to_i}
		@password_link = "#{callback}?key=" + CGI::escape(Encryption.encrypt_activate_key(password_info.to_json))
		email = Rails.env == "production" ? user.email : @@test_email
		mail(:to => email, :subject => "重置密码")
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
		mail(:to => email, :subject => "恭喜您获得抽奖号")
	end

	def survey_email(user_id, survey_id_ary)
		@user = User.find_by_id(user_id)
		@surveys = survey_id_ary.map { |e| Survey.find_by_id(e) }
		@surveys.each do |s|
			email_history = EmailHistory.create
			email_history.user = @user
			email_history.survey = s
			email_history.save
		end
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
		email = Rails.env == "production" ? user.email : @@test_email
		mail(:to => email, :subject => "邀请您参加问卷调查")
	end

	def imported_email_survey_email(email, survey_id_ary)
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
		email = Rails.env == "production" ? email : @@test_email
		mail(:to => email, :subject => "邀请您参加问卷调查")
	end
	
	def publish_email(publish_status_history)
		@survey = Survey.find_by_id(publish_status_history.survey_id)
		@user = User.find_by_email(@survey.owner_email)
		@message = publish_status_history.message
		@url = "#{Rails.application.config.quill_host}/questionaires/#{@survey._id.to_s}/share"
		email = Rails.env == "production" ? @user.email : @@test_email
		mail(:to => email, :subject => "您的调查问卷 #{@survey.title} 已经发布")
	end
	
	def reject_email(publish_status_history)
		@survey = Survey.find_by_id(publish_status_history.survey_id)
		@user = @survey.user
		@message = publish_status_history.message
		@url = "#{Rails.application.config.quill_host}/questionaires/#{@survey._id.to_s}"
		email = Rails.env == "production" ? @user.email : @@test_email
		mail(:to => email, :subject => "您的调查问卷 #{@survey.title} 发布申请被拒绝")
	end
end
