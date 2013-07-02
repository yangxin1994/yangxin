#encoding: utf-8
class MailgunApi

	@@test_email = "test@oopsdata.com"

	@@survey_email_from = "\"优数调研\" <postmaster@oopsdata.net>"
	@@user_email_from = "\"优数调研\" <postmaster@oopsdata.cn>"

	def self.batch_send_survey_email(survey_id_ary, user_id_ary, email_ary)
		@emails = email_ary.blank? ? user_id_ary.map { |e| User.find_by_id(e).try(:email) } : email_ary
		group_size = 900
		@group_emails = []
		@group_recipient_variables = []
		while @emails.length >= group_size
			temp_emails = @emails[0..group_size-1]
			@group_emails << temp_emails
			@emails = @emails[group_size..-1]
			temp_recipient_variables = {}
			temp_emails.each do |e|
				temp_recipient_variables[e] = {}
			end
			@group_recipient_variables << temp_recipient_variables
		end
		@group_emails << @emails
		temp_recipient_variables = {}
		@emails.each do |e|
			temp_recipient_variables[e] = {}
		end
		@group_recipient_variables << temp_recipient_variables

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
		data[:subject] += " --- to #{@group_emails.flatten.length} emails" if Rails.env != "production" 
		@group_emails.each_with_index do |emails, i|
			data[:to] = Rails.env == "production" ? emails.join(', ') : @@test_email
			data[:'recipient-variables'] = @group_recipient_variables[i].to_json
			self.send_message(data)
		end
	end

=begin
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
		data[:subject] += " --- to #{@email}" if Rails.env != "production" 
		data[:to] = Rails.env == "production" ? @email : @@test_email
		self.send_message(data)
	end
=end

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

	def self.agent_task_email(email, callback, agent_task_id)
		@agent_task = AgentTask.find_by_id(agent_task_id)
		@survey = @agent_task.survey
		@survey_title = @survey.title
		@preview_link = "#{callback}/questionaires/#{@survey._id.to_s}/preview"
		@email = email
		@password = Encryption.decrypt_password(@agent_task.password)
		data = {}
		data[:domain] = Rails.application.config.user_email_domain
		data[:from] = @@user_email_from

		html_template_file_name = "#{Rails.root}/app/views/agent_mailer/agent_task_email.html.erb"
		text_template_file_name = "#{Rails.root}/app/views/agent_mailer/agent_task_email.text.erb"
		html_template = ERB.new(File.new(html_template_file_name).read, nil, "%")
		text_template = ERB.new(File.new(text_template_file_name).read, nil, "%")
		premailer = Premailer.new(html_template.result(binding), :warn_level => Premailer::Warnings::SAFE)
		data[:html] = premailer.to_inline_css
		data[:text] = text_template.result(binding)

		data[:subject] = "优数代理推广任务启动通知"
		data[:subject] += " --- to #{email}" if Rails.env != "production" 
		data[:to] = Rails.env == "production" ? email : @@test_email
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
		# domain = data.delete(:domain)
		domain = data[:domain]
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
