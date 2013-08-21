#encoding: utf-8
require 'rubygems'
require 'httparty'

class SmsApi # 短信接口

	attr_reader :phone_number, :message

	include HTTParty
	base_uri 'http://sdkhttp.eucp.b2m.cn'
	format  :xml

	def initialize(phone_number, message)
		@phone_number = phone_number
		@message = message
	end

	CDKEY = "0SDK-EBB-0130-NEXUR"
	PASSWORD = '007266'
	AUTOGRAPH = '［优数调研］'
	##### 注意: 不能使用短信接口发送个人信息(如"老地方见","你在哪"之类)                   #####
	##### 否则短信平台会封掉接口，测试时只写两个字"内部测试"加其他必要的程序信息(如校验码)#####
	##### 注意!注意!注意!注意!注意!注意!注意!注意!注意!注意!注意!注意!注意!注意注意!!注意!#####

	#序列号注册  web容器第一次启动的时候需要激活该序列号
	def self.regist_serival_number
		result = get('/sdkproxy/regist.action', :query => {:cdkey => SMS::CDKEY,:password => SMS::PASSWORD })
		puts result.parsed_response
	end

	#注册企业信息  web容器第一次启动的时候，需要注册本企业的相关信息
	def self.regist_company_info
		result = get('/sdkproxy/registdetailinfo.action',
				:query => {:cdkey    => SMS::CDKEY,
									:password => SMS::PASSWORD,
									:ename    => '优数调研',
									:linkman  => '杨泽曦',
									:phonenum => '13488881477',
									:mobile   => '13488881477',
									:email    => 'yangzexi@oopsdata.com',
									:fax      => '010-62800785',
									:address  => '北京市海淀区五道口',
									:postcode => '100083'
									})
		puts result.parsed_response
	end

	#同步发送即时短信
	def self.send_sms(phone, message)
		return if Rails.env != "production"
		result = get('/sdkproxy/sendsms.action',
				:query => {:cdkey    => SMS::CDKEY,
									 :password => SMS::PASSWORD,
									 :phone    => phone,
									 :message  => message
									})
	end

	#查询短信剩余条数
	def self.get_remainder
		result = get('/sdkproxy/querybalance.action',
			:query => {:cdkey    => SMS::CDKEY,
			:password => SMS::PASSWORD  
			})
		puts result.parsed_response
		remainder = result.parsed_response['response']['message'].to_f * 10 
		return remainder
	end

	#发送定时短信
	#sendtime format : yyyymmddhhnnss
	def self.send_time_sms(phone,message, sendtime)
		get('/sdkproxy/sendtimesms.action',
				:query => {:cdkey    => SMS::CDKEY,
									 :password => SMS::PASSWORD,
									 :phone    => phone,
									 :message  => message + AUTOGRAPH,
									 :sendtime => sendtime
									 })
	end


	################### different types of sms ########################

	def self.invitation_sms(survey_id, sample_id, callback, opt)
		sample = User.find_by_id(sample_id)
		return if sample.nil? || sample.mobile.blank?
		mobile = sample.mobile
		survey = Survey.find_by_id(survey_id)
		@survey_title = survey.title
		reward_scheme_id = survey.sms_promote_info["reward_scheme_id"]
		@survey_link = "#{Rails.application.config.quillme_host}/s/#{reward_scheme_id}"
		@survey_link = Rails.application.config.quillme_host + "/" + MongoidShortener.generate(@survey_link)
		unsubscribe_key = CGI::escape(Encryption.encrypt_activate_key({"email_mobile" => mobile}.to_json))
		@unsubscribe_link = "#{Rails.application.config.quillme_host}/surveys/cancel_subscribe?key=#{unsubscribe_key}"
		@unsubscribe_link = Rails.application.config.quillme_host + "/" + MongoidShortener.generate(@unsubscribe_link)

		@reward = ""
		reward_scheme = RewardScheme.find_by_id(reward_scheme_id)
		if reward_scheme.rewards[0].present?
			case reward_scheme.rewards[0]["type"]
			when RewardScheme::MOBILE
				@reward = "#{reward_scheme.rewards[0]["amount"]}现金奖励"
			when RewardScheme::ALIPAY
				@reward = "#{reward_scheme.rewards[0]["amount"]}现金奖励"
			when RewardScheme::JIFENBAO
				@reward = "#{reward_scheme.rewards[0]["amount"]}现金奖励"
			when RewardScheme::POINT
				@reward = "#{reward_scheme.rewards[0]["amount"]}积分奖励"
			when RewardScheme::LOTTERY
				@reward = "一次抽奖机会"
			end
		end

		text_template_file_name = "#{Rails.root}/app/views/sms_text/invitation_sms.text.erb"
		text_template = ERB.new(File.new(text_template_file_name).read, nil, "%")
		text = text_template.result(binding)
		self.send_sms(mobile, text)
	end

	def self.find_password_sms(mobile, callback, opt)
		@code = opt["code"].to_s
		text_template_file_name = "#{Rails.root}/app/views/sms_text/find_password_sms.text.erb"
		text_template = ERB.new(File.new(text_template_file_name).read, nil, "%")
		text = text_template.result(binding)
		self.send_sms(mobile, text)
	end

	def self.change_mobile_sms(mobile, callback, opt)
		@code = opt["code"].to_s
		text_template_file_name = "#{Rails.root}/app/views/sms_text/change_mobile_sms.text.erb"
		text_template = ERB.new(File.new(text_template_file_name).read, nil, "%")
		text = text_template.result(binding)
		self.send_sms(mobile, text)
	end
	
	def self.rss_subscribe_sms(mobile, callback, opt)
		@code = opt["code"].to_s
		text_template_file_name = "#{Rails.root}/app/views/sms_text/rss_subscribe_sms.text.erb"
		text_template = ERB.new(File.new(text_template_file_name).read, nil, "%")
		text = text_template.result(binding)
		self.send_sms(mobile, text)
	end

	def self.activate_sms(mobile, callback, opt)
		@code = opt["code"].to_s
		text_template_file_name = "#{Rails.root}/app/views/sms_text/activate_sms.text.erb"
		text_template = ERB.new(File.new(text_template_file_name).read, nil, "%")
		text = text_template.result(binding)
		self.send_sms(mobile, text)
	end

	def self.welcome_sms(mobile, callback, opt)
		@code = opt["active_code"].to_s
		text_template_file_name = "#{Rails.root}/app/views/sms_text/welcome_sms.text.erb"
		text_template = ERB.new(File.new(text_template_file_name).read, nil, "%")
		text = text_template.result(binding)
		self.send_sms(mobile, text)
	end

	def self.charge_confirm_sms(mobile, callback, opt)
		@gift_name = opt[:gift_name].to_s
		text_template_file_name = "#{Rails.root}/app/views/sms_text/charge_confirm_sms.text.erb"
		text_template = ERB.new(File.new(text_template_file_name).read, nil, "%")
		text = text_template.result(binding)
		self.send_sms(mobile, text)
	end
end