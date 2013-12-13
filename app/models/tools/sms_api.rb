#encoding: utf-8
require 'rubygems'
require 'httparty'

class SmsApi # 短信接口

  attr_reader :phone_number, :message

  include HTTParty
  base_uri "http://smsapi.c123.cn"
  format  :xml

  def initialize(phone_number, message)
    @phone_number = phone_number
    @message = message
  end

  AC = "1001@500787040001"
  AUTHKEY = '14C1984315390F6E2E4054A13AA6E3F1'
  CGID = 52


  def self.send_sms(mobile, message)
    query_p = {action: "sendOnce", ac: AC, authkey: AUTHKEY, cgid: CGID, c: message, m: mobile}
    result = get('/OpenPlatform/OpenApi',
        :query => query_p)
    binding.pry
    puts result.inspect
  end

  def self.send_param_sms(mobiles, message, params)
    query_p = {action: "sendParam", ac: AC, authkey: AUTHKEY, cgid: CGID, c: message, m: mobiles.join(',')}
    params.each_with_index do |param, index|
      query_p["p#{index+1}".to_sym] = param.join("{|}")
    end
    result = get('/OpenPlatform/OpenApi',
        :query => query_p)
    binding.pry
    puts result.inspect
  end

  def self.get_status
    query_p = {action: "getSendState", ac: AC, authkey: AUTHKEY}
    result = get('/OpenPlatform/DataApi',
        :query => query_p)
    binding.pry
    puts result.inspect
  end

  ################### different types of sms ########################

  def self.invitation_sms(survey_id, sample_id, callback, opt = {})
    sample = User.find_by_id(sample_id)
    return if sample.nil? || sample.mobile.blank?
    mobile = sample.mobile
    survey = Survey.find_by_id(survey_id)
    @survey_title = survey.title
    reward_scheme_id = survey.sms_promote_info["reward_scheme_id"]
    @survey_link = "#{Rails.application.config.quillme_host}/s/#{reward_scheme_id}"
    if sample.status == User::REGISTERED
      sample.auth_key = Encryption.encrypt_auth_key("#{sample._id}&#{Time.now.to_i.to_s}")
      sample.auth_key_expire_time =  -1
      sample.save
      @survey_link += "?auth_key=#{sample.auth_key}"
    end
    @survey_link = Rails.application.config.quillme_host + "/" + MongoidShortener.generate(@survey_link)
    unsubscribe_key = CGI::escape(Encryption.encrypt_activate_key({"email_mobile" => mobile}.to_json))
    @unsubscribe_link = "#{Rails.application.config.quillme_host}/surveys/cancel_subscribe?key=#{unsubscribe_key}"
    @unsubscribe_link = Rails.application.config.quillme_host + "/" + MongoidShortener.generate(@unsubscribe_link)

    @reward = ""
    reward_scheme = RewardScheme.find_by_id(reward_scheme_id)
    if reward_scheme && reward_scheme.rewards[0].present?
      case reward_scheme.rewards[0]["type"]
      when RewardScheme::MOBILE
          @reward = "#{reward_scheme.rewards[0]["amount"]}元现金奖励"
      when RewardScheme::ALIPAY
          @reward = "#{reward_scheme.rewards[0]["amount"]}元现金奖励"
      when RewardScheme::JIFENBAO
          @reward = "#{reward_scheme.rewards[0]["amount"]}元现金奖励"
      when RewardScheme::POINT
          @reward = "#{reward_scheme.rewards[0]["amount"]}积分奖励"
      when RewardScheme::LOTTERY
          @reward = "一次抽奖机会"
      end
    end

    text_template_file_name = "#{Rails.root}/app/views/sms_text/invitation_sms.text.erb"
    text_template = ERB.new(File.new(text_template_file_name).read, nil, "%")
    text = text_template.result(binding)
    self.send_sms('invitation',mobile, text)
  end

  def self.find_password_sms(type,mobile, callback, opt)
    @code = opt["code"].to_s
    text_template_file_name = "#{Rails.root}/app/views/sms_text/find_password_sms.text.erb"
    text_template = ERB.new(File.new(text_template_file_name).read, nil, "%")
    text = text_template.result(binding)
    self.send_sms(type,mobile, text)
  end

  def self.change_mobile_sms(mobile, callback, opt)
    @code = opt["code"].to_s
    text_template_file_name = "#{Rails.root}/app/views/sms_text/change_mobile_sms.text.erb"
    text_template = ERB.new(File.new(text_template_file_name).read, nil, "%")
    text = text_template.result(binding)
    self.send_sms(mobile, text)
  end
  
  def self.rss_subscribe_sms(type,mobile, callback, opt)
    @code = opt["code"].to_s
    text_template_file_name = "#{Rails.root}/app/views/sms_text/rss_subscribe_sms.text.erb"
    text_template = ERB.new(File.new(text_template_file_name).read, nil, "%")
    text = text_template.result(binding)
    self.send_sms(type,mobile, text)
  end

  def self.activate_sms(type,mobile, callback, opt)
    @code = opt["code"].to_s
    text_template_file_name = "#{Rails.root}/app/views/sms_text/activate_sms.text.erb"
    text_template = ERB.new(File.new(text_template_file_name).read, nil, "%")
    text = text_template.result(binding)
    self.send_sms(type,mobile, text)
  end

  def self.welcome_sms(type,mobile, callback, opt)
    @code = opt["active_code"].to_s
    text_template_file_name = "#{Rails.root}/app/views/sms_text/welcome_sms.text.erb"
    text_template = ERB.new(File.new(text_template_file_name).read, nil, "%")
    text = text_template.result(binding)
    self.send_sms(type,mobile, text)
  end

  def self.charge_confirm_sms(mobile, callback, opt)
    @gift_name = opt[:gift_name].to_s
    text_template_file_name = "#{Rails.root}/app/views/sms_text/charge_confirm_sms.text.erb"
    text_template = ERB.new(File.new(text_template_file_name).read, nil, "%")
    text = text_template.result(binding)
    self.send_sms(mobile, text)
  end
end
