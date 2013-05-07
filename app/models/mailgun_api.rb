#encoding: utf-8
class MailgunApi

	@@test_email = "test@oopsdata.com"

	@@survey_email_from = "\"优数调研\" <postmaster@oopsdata.net>"
	@@user_email_from = "\"优数调研\" <postmaster@oopsdata.cn>"

	def self.send_survey_email(user_id, email, survey_id_ary)
		if user_id.blank?
			@email = email
		else
			user = User.find_by_id(user_id)
			@email = user.email
			return if @email.blank?
		end

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

		data = {}
		data[:domain] = Rails.application.config.survey_email_domain
		data[:from] = @@survey_email_from

		html_template_file_name = "#{Rails.root}/app/views/survey_mailer/survey_email.html.erb"
		text_template_file_name = "#{Rails.root}/app/views/survey_mailer/survey_email.text.erb"
		html_template = ERB.new(File.new(html_template_file_name).read, nil, "%")
		text_template = ERB.new(File.new(text_template_file_name).read, nil, "%")
		premailer = Premailer.new(html_template.result(binding), :warn_level => Premailer::Warnings::SAFE)
		data[:html] = premailer.to_inline_css
		data[:text] = text_template.result(binding)

		data[:subject] = "邀请您参加问卷调查"
		data[:subject] += " --- to #{@email}" if Rails.env == "production" 
		data[:to] = Rails.env == "production" ? @email : @@test_email
		self.send_message(data)
	end

	def self.welcome_email(user, callback)
		@user = user
		activate_info = {"email" => user.email, "time" => Time.now.to_i}
		@activate_link = "#{callback}?key=" + CGI::escape(Encryption.encrypt_activate_key(activate_info.to_json))
		data = {}
		data[:domain] = Rails.application.config.user_email_domain
		data[:from] = @@user_email_from

		html_template_file_name = "#{Rails.root}/app/views/user_mailer/welcome_email.html.erb"
		text_template_file_name = "#{Rails.root}/app/views/user_mailer/welcome_email.text.erb"
		html_template = ERB.new(File.new(html_template_file_name).read, nil, "%")
		text_template = ERB.new(File.new(text_template_file_name).read, nil, "%")
		premailer = Premailer.new(html_template.result(binding), :warn_level => Premailer::Warnings::SAFE)
		data[:html] = premailer.to_inline_css
		data[:text] = text_template.result(binding)

		data[:subject] = "欢迎注册优数调研"
		data[:subject] += " --- to #{user.email}" if Rails.env != "production" 
		data[:to] = Rails.env == "production" ? user.email : @@test_email
		self.send_message(data)
	end

	def self.activate_email(user, callback)
		@user = user
		activate_info = {"email" => user.email, "time" => Time.now.to_i}
		@activate_link = "#{callback}?key=" + CGI::escape(Encryption.encrypt_activate_key(activate_info.to_json))
		data = {}
		data[:domain] = Rails.application.config.user_email_domain
		data[:from] = @@user_email_from

		html_template_file_name = "#{Rails.root}/app/views/user_mailer/activate_email.html.erb"
		text_template_file_name = "#{Rails.root}/app/views/user_mailer/activate_email.text.erb"
		html_template = ERB.new(File.new(html_template_file_name).read, nil, "%")
		text_template = ERB.new(File.new(text_template_file_name).read, nil, "%")
		premailer = Premailer.new(html_template.result(binding), :warn_level => Premailer::Warnings::SAFE)
		data[:html] = premailer.to_inline_css
		data[:text] = text_template.result(binding)

		data[:subject] = "激活账户"
		data[:subject] += " --- to #{user.email}" if Rails.env != "production" 
		data[:to] = Rails.env == "production" ? user.email : @@test_email
		self.send_message(data)
	end

	def self.password_email(user, callback)
		@user = user
		password_info = {"email" => user.email, "time" => Time.now.to_i}
		@password_link = "#{callback}?key=" + CGI::escape(Encryption.encrypt_activate_key(password_info.to_json))
		data = {}
		data[:domain] = Rails.application.config.user_email_domain
		data[:from] = @@user_email_from

		html_template_file_name = "#{Rails.root}/app/views/user_mailer/password_email.html.erb"
		text_template_file_name = "#{Rails.root}/app/views/user_mailer/password_email.text.erb"
		html_template = ERB.new(File.new(html_template_file_name).read, nil, "%")
		text_template = ERB.new(File.new(text_template_file_name).read, nil, "%")
		premailer = Premailer.new(html_template.result(binding), :warn_level => Premailer::Warnings::SAFE)
		data[:html] = premailer.to_inline_css
		data[:text] = text_template.result(binding)

		data[:subject] = "重置密码"
		data[:subject] += " --- to #{user.email}" if Rails.env != "production" 
		data[:to] = Rails.env == "production" ? user.email : @@test_email
		self.send_message(data)
	end

	def self.sys_password_email(user, callback)
		@user = user
		data = {}
		data[:domain] = Rails.application.config.user_email_domain
		data[:from] = @@user_email_from

		html_template_file_name = "#{Rails.root}/app/views/user_mailer/sys_password_email.html.erb"
		text_template_file_name = "#{Rails.root}/app/views/user_mailer/sys_password_email.text.erb"
		html_template = ERB.new(File.new(html_template_file_name).read, nil, "%")
		text_template = ERB.new(File.new(text_template_file_name).read, nil, "%")
		premailer = Premailer.new(html_template.result(binding), :warn_level => Premailer::Warnings::SAFE)
		data[:html] = premailer.to_inline_css
		data[:text] = text_template.result(binding)

		data[:subject] = "您的邮箱刚刚创建了Oopsdata的账号"
		data[:subject] += " --- to #{user.email}" if Rails.env != "production" 
		data[:to] = Rails.env == "production" ? user.email : @@test_email
		self.send_message(data)
	end

	def self.lottery_code_email(user, survey_id, lottery_code_id, callback)
		@user = user
		@survey = Survey.find_by_id(survey_id)
		@lottery_code = LotteryCode.where(:_id => lottery_code_id).first
		lottery = @lottery_code.try(:lottery)
		@survey_list_url = "#{Rails.application.config.quillme_host}/surveys"
		@lottery_url = "#{Rails.application.config.quillme_host}/lotteries/#{lottery.try(:_id)}"
		@lottery_title = lottery.try(:title)
		@lottery_code_url = "#{Rails.application.config.quillme_host}/lotteries/own"
		data = {}
		data[:domain] = Rails.application.config.user_email_domain
		data[:from] = @@user_email_from

		html_template_file_name = "#{Rails.root}/app/views/user_mailer/lottery_code_email.html.erb"
		text_template_file_name = "#{Rails.root}/app/views/user_mailer/lottery_code_email.text.erb"
		html_template = ERB.new(File.new(html_template_file_name).read, nil, "%")
		text_template = ERB.new(File.new(text_template_file_name).read, nil, "%")
		premailer = Premailer.new(html_template.result(binding), :warn_level => Premailer::Warnings::SAFE)
		data[:html] = premailer.to_inline_css
		data[:text] = text_template.result(binding)

		data[:subject] = "恭喜您获得抽奖号"
		data[:subject] += " --- to #{user.email}" if Rails.env != "production" 
		data[:to] = Rails.env == "production" ? user.email : @@test_email
		self.send_message(data)
	end

	def self.send_message(data)
		domain = data.delete(:domain)
		retval = RestClient.post("https://api:#{Rails.application.config.mailgun_api_key}"\
		  "@api.mailgun.net/v2/#{domain}/messages", data)
		begin
			retval = JSON.parse(retval)
			return retval["id"]
		rescue
			return -1
		end
	end
end
