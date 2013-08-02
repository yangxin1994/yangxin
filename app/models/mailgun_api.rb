#encoding: utf-8
class MailgunApi

	@@test_email = "test@oopsdata.com"

	@@survey_email_from = "\"问卷吧\" <postmaster@oopsdata.net>"
	@@user_email_from = "\"问卷吧\" <postmaster@oopsdata.cn>"

	def self.batch_send_survey_email(survey_id, user_id_ary)
		@emails = user_id_ary.map { |e| User.find_by_id(e).try(:email) }
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

		@survey = Survey.find_by_id(survey_id)
		@reward_scheme_id = @survey.email_promote_info["reward_scheme_id"]

		@reward_scheme = RewardScheme.find_by_id(@reward_scheme_id)
		@reward_type = @reward_scheme.rewards[0]["type"]
		if [RewardScheme::MOBILE, RewardScheme::ALIPAY, RewardScheme::JIFENBAO, RewardScheme::POINT].include? @reward_type
			amount = @reward_scheme.rewards[0]["amount"]
			@amount = @reward == RewardScheme::JIFENBAO ? amount / 100 : amount
		end

		if [RewardScheme::MOBILE, RewardScheme::ALIPAY, RewardScheme::JIFENBAO, RewardScheme::POINT].include? @reward_type
			# list some hot gifts
			@gifts = []
			Gift.all.desc(:exchange_count).limit(3).each do |g|
				@gifts << { :title => g.title,
					:url => Rails.application.config.quillme_host + "/gifts/" + g._id.to_s,
					:img_url => Rails.application.config.quillme_host + g.photo.picture_url }
			end
			# get redeem logs
			@redeem_logs = []
			RedeemLog.all.desc(:created_at).limit(3).each do |redeem_log|
				time = Tool.time_string(Time.now.to_i - redeem_log.created_at.to_i)
				@redeem_logs << { :time => time,
					:nickname => redeem_log.user.nickname,
					:amount => redeem_log.amount,
					:gift_title => redeem_log.gift_title }
			end
		else
			# list the prizes
			@prizes = []
			@reward_scheme.rewards[0]["prizes"].each do |p|
				prize = Prize.find_by_id(p["prize_id"])
				next if prize.nli?
				@prizes << { :title => prize.title,
					:img_url => Rails.application.config.quillme_host + prize.photo.picture_url }
			end
			# get lottery logs
			@lottery_logs = []
			LotteryLog.all.desc(:created_at).limit(9).each do |lottery_log|
				@lottery_logs << { :nickname => lottery_log.user.try(:nickname) || "游客", 
					:region => lottery_log.land,
					:avatar_url => Rails.application.config.quillme_host + Tool.mini_avatar(lottery_log.user.try(:_id))}
			end
		end

		data = {}
		data[:domain] = Rails.application.config.survey_email_domain
		data[:from] = @@survey_email_from

		html_template_file_name = "#{Rails.root}/app/views/survey_mailer/push_email.html.erb"
		text_template_file_name = "#{Rails.root}/app/views/survey_mailer/push_email.text.erb"
		html_template = ERB.new(File.new(html_template_file_name).read, nil, "%")
		text_template = ERB.new(File.new(text_template_file_name).read, nil, "%")
		premailer = Premailer.new(html_template.result(binding), :warn_level => Premailer::Warnings::SAFE)
		data[:html] = premailer.to_inline_css
		data[:text] = text_template.result(binding)

		data[:subject] = "邀请您参加问卷调查"
		data[:subject] += " --- to #{@group_emails.flatten.length} emails" if Rails.env != "production" 
		puts "AAAAAAAAAAAAAAAAAAAAAA"
		@group_emails.each_with_index do |emails, i|
			puts "BBBBBBBBBBBBBBBBBBBBBB"
			puts emails.inspect
			data[:to] = Rails.env == "production" ? emails.join(', ') : @@test_email
			data[:'recipient-variables'] = @group_recipient_variables[i].to_json
			self.send_message(data)
		end
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

		data[:subject] = "欢迎注册问卷吧"
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

	def self.find_password_email(user, callback)
		@user = user
		password_info = {"email" => user.email, "time" => Time.now.to_i}
		@password_link = "#{callback}?key=" + CGI::escape(Encryption.encrypt_activate_key(password_info.to_json))
		data = {}
		data[:domain] = Rails.application.config.user_email_domain
		data[:from] = @@user_email_from

		html_template_file_name = "#{Rails.root}/app/views/user_mailer/find_password_email.html.erb"
		text_template_file_name = "#{Rails.root}/app/views/user_mailer/find_password_email.text.erb"
		html_template = ERB.new(File.new(html_template_file_name).read, nil, "%")
		text_template = ERB.new(File.new(text_template_file_name).read, nil, "%")
		premailer = Premailer.new(html_template.result(binding), :warn_level => Premailer::Warnings::SAFE)
		data[:html] = premailer.to_inline_css
		data[:text] = text_template.result(binding)

		data[:subject] = "找回密码"
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

	def self.rss_subscribe_email(user, callback)
		@user = user
		activate_info = {"email" => user.email, "time" => Time.now.to_i}
		@activate_link = "#{callback}?key=" + CGI::escape(Encryption.encrypt_activate_key(activate_info.to_json))
		data = {}
		data[:domain] = Rails.application.config.user_email_domain
		data[:from] = @@user_email_from

		html_template_file_name = "#{Rails.root}/app/views/user_mailer/rss_email.html.erb"
		text_template_file_name = "#{Rails.root}/app/views/user_mailer/rss_email.text.erb"
		html_template = ERB.new(File.new(html_template_file_name).read, nil, "%")
		text_template = ERB.new(File.new(text_template_file_name).read, nil, "%")
		premailer = Premailer.new(html_template.result(binding), :warn_level => Premailer::Warnings::SAFE)
		data[:html] = premailer.to_inline_css
		data[:text] = text_template.result(binding)

		data[:subject] = "欢迎订阅问卷吧"
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
