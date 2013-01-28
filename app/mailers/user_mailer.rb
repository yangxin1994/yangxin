# encoding: utf-8
require 'encryption'
class UserMailer < ActionMailer::Base
	layout 'email'

  default from: "\"优数调研\" <postmaster@oopsdata.net>", charset: "UTF-8"

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
		mail(:to => user.email, :subject => "激活账户")
	end
	
	def password_email(user, callback)
		@user = user
		password_info = {"email" => user.email, "time" => Time.now.to_i}
		@password_link = "#{callback}?key=" + CGI::escape(Encryption.encrypt_activate_key(password_info.to_json))
		mail(:to => user.email, :subject => "重置密码")
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
		mail(:to => user.email, :subject => "恭喜您获得抽奖号")
	end

	def survey_email(user_id, survey_id_ary)
		@user = User.find_by_id(user_id)
		@surveys = survey_id_ary.map { |e| Survey.find_by_id(e) }
		@surveys.each do |s|
			email_history = EmailHistory.create
			email_history.user = @user
			email_history.survey = s
		end
		#TODO: 获取问卷的奖励信息，并修改 survey_email.html.erb、survey_email.text.erb 内容
		@presents = []	
		#TODO: presents 数组内容为显示在 quillme 的：一个抽奖、一个实物礼品、一个红包礼品，
		# 元素结构为： {:title => "", :url => "", :img_url => ""}，
		# url 里需要用到的 host 为：Rails.application.config.quillme_host
		# 抽奖地址为："#{Rails.application.config.quillme_host}/lotteries/lottery_id"
		# 礼品地址为："#{Rails.application.config.quillme_host}/gifts/gift_id"
		# img_url为："#{Rails.application.config.quillme_host}/uploads/images/filename"
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
