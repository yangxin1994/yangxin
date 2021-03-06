#encoding: utf-8
class MailgunApi

  @@test_email = "test@oopsdata.com"

  @@survey_email_from = "\"问卷吧\" <postmaster@wenjuanba.net>"
  @@user_email_from = "\"问卷吧\" <postmaster@wenjuanba.cn>"

  def self.batch_send_carnival_email(number)
    @emails = (User.all.select { |e| e.email.present? && !e.carnival_email_sent } )[0..number - 1].map { |e| e.email }
    # @emails = ["jesse.yang1985@gmail.com", "yangzexi@126.com"]
    group_size = 900
    # @group_emails = @emails.each_slice(group_size).to_a

    @group_emails = []
    @group_recipient_variables = []
    while @emails.length >= group_size
      temp_emails = @emails[0..group_size-1]
      @group_emails << temp_emails
      @emails = @emails[group_size..-1]
      temp_recipient_variables = {}
      temp_emails.each do |e|
        temp_recipient_variables[e] = { }
      end
      @group_recipient_variables << temp_recipient_variables
    end
    @group_emails << @emails
    temp_recipient_variables = { }
    @emails.each do |e|
      temp_recipient_variables[e] = { }
    end
    @group_recipient_variables << temp_recipient_variables

    html_template_file_name = "#{Rails.root}/app/views/survey_mailer/carnival_email.html.erb"
    html_template = ERB.new(File.new(html_template_file_name).read, nil, "%")
    premailer = Premailer.new(html_template.result(binding), :warn_level => Premailer::Warnings::SAFE)

    @group_emails.each do |emails|
      emails.each do |e|
        u = User.find_by_email(e)
        u.update_attributes(carnival_email_sent: true) if u.present?
      end
    end

    @group_emails.each_with_index do |emails, i|
      data = {}
      data[:domain] = Rails.application.config.survey_email_domain
      data[:from] = @@survey_email_from
      data[:html] = premailer.to_inline_css
      data[:subject] = "问卷吧嘉年华重磅来袭"
      data[:subject] += " --- to #{@group_emails.flatten.length} emails" if Rails.env != "production" 
      data[:to] = Rails.env == "production" ? emails.join(', ') : @@test_email
      data[:'recipient-variables'] = @group_recipient_variables[i].to_json
      self.send_message(data)
    end
  end

  def self.batch_send_pre_survey_email(survey_id, emails, reward_scheme_id)
    @emails = emails
    group_size = 900
    @group_emails = @emails.each_slice(group_size).to_a
    @survey = Survey.find_by_id(survey_id)
    @reward_scheme_id = reward_scheme_id
    @reward_scheme = RewardScheme.find_by_id(reward_scheme_id)

    @reward_type = @reward_scheme.rewards.length > 0 ? @reward_scheme.rewards[0]["type"] : nil
    @reward_name = ""
    case @reward_type
    when RewardScheme::MOBILE
      @reward_name = "手机话费"
    when RewardScheme::JIFENBAO
      @reward_name = "集分宝"
    when RewardScheme::ALIPAY
      @reward_name = "支付宝"
    end
    if [RewardScheme::MOBILE, RewardScheme::ALIPAY, RewardScheme::JIFENBAO, RewardScheme::POINT].include? @reward_type
      amount = @reward_scheme.rewards[0]["amount"]
      @amount = @reward == RewardScheme::JIFENBAO ? amount / 100 : amount
    end

    if [RewardScheme::MOBILE, RewardScheme::ALIPAY, RewardScheme::JIFENBAO, RewardScheme::POINT].include? @reward_type || @reward_type.nil?
      # list some hot gifts
      @gifts = []
      Gift.on_shelf.real_and_virtual.desc(:exchange_count).limit(3).each do |g|
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
          :point => redeem_log.point,
          :gift_name => redeem_log.gift_name }
      end
    elsif @reward_type.present?
      # list the prizes
      @prizes = []
      @reward_scheme.rewards[0]["prizes"].each do |p|
        prize = Prize.normal.find_by_id(p["id"])
        next if prize.nil?
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
      @lottery_logs = @lottery_logs.each_slice(3).to_a
    end


    html_template_file_name = "#{Rails.root}/app/views/survey_mailer/pre_survey_email.html.erb"
    text_template_file_name = "#{Rails.root}/app/views/survey_mailer/pre_survey_email.text.erb"
    html_template = ERB.new(File.new(html_template_file_name).read, nil, "%")
    text_template = ERB.new(File.new(text_template_file_name).read, nil, "%")
    premailer = Premailer.new(html_template.result(binding), :warn_level => Premailer::Warnings::SAFE)

    @group_emails.each_with_index do |emails, i|
      data = {}
      data[:domain] = Rails.application.config.survey_email_domain
      data[:from] = @@survey_email_from
      data[:html] = premailer.to_inline_css
      data[:text] = text_template.result(binding)
      data[:subject] = "邀请您参加问卷调查"
      data[:subject] += " --- to #{@group_emails.flatten.length} emails" if Rails.env != "production" 
      data[:to] = Rails.env == "production" ? emails.join(', ') : @@test_email
      self.send_message(data)
    end
  end

  def self.batch_send_survey_email(survey_id, user_id_ary)
    return if user_id_ary.blank?
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
        u = User.find_by_email(e)
        if u.status == User::REGISTERED
          u.auth_key = Encryption.encrypt_auth_key("#{u._id}&#{Time.now.to_i.to_s}")
          u.auth_key_expire_time =  -1
          u.save
        end
        unsubscribe_key = CGI::escape(Encryption.encrypt_activate_key({"email_mobile" => e}.to_json))
        temp_recipient_variables[e] = {"auth_key" => u.auth_key, "unsubscribe_key" => unsubscribe_key}
      end
      @group_recipient_variables << temp_recipient_variables
    end
    @group_emails << @emails
    temp_recipient_variables = {}
    @emails.each do |e|
      u = User.find_by_email(e)
      if u.status == User::REGISTERED
        u.auth_key = Encryption.encrypt_auth_key("#{u._id}&#{Time.now.to_i.to_s}")
        u.auth_key_expire_time =  -1
        u.save
      end
      unsubscribe_key = CGI::escape(Encryption.encrypt_activate_key({"email_mobile" => e}.to_json))
      temp_recipient_variables[e] = {"auth_key" => u.auth_key, "unsubscribe_key" => unsubscribe_key}
    end
    @group_recipient_variables << temp_recipient_variables


    @survey = Survey.find_by_id(survey_id)
    @reward_scheme_id = @survey.email_promote_info["reward_scheme_id"]

    @reward_scheme = RewardScheme.find_by_id(@reward_scheme_id)

    @reward_type = @reward_scheme.rewards.length > 0 ? @reward_scheme.rewards[0]["type"] : nil
    if [RewardScheme::MOBILE, RewardScheme::ALIPAY, RewardScheme::JIFENBAO, RewardScheme::POINT].include? @reward_type
      amount = @reward_scheme.rewards[0]["amount"]
      @amount = @reward == RewardScheme::JIFENBAO ? amount / 100 : amount
    end

    if [RewardScheme::MOBILE, RewardScheme::ALIPAY, RewardScheme::JIFENBAO, RewardScheme::POINT].include? @reward_type || @reward_type.nil?
      # list some hot gifts
      @gifts = []
      Gift.on_shelf.real_and_virtual.desc(:exchange_count).limit(3).each do |g|
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
          :point => redeem_log.point,
          :gift_name => redeem_log.gift_name }
      end
    elsif @reward_type.present?
      # list the prizes
      @prizes = []
      @reward_scheme.rewards[0]["prizes"].each do |p|
        prize = Prize.normal.find_by_id(p["id"])
        next if prize.nil?
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
      @lottery_logs = @lottery_logs.each_slice(3).to_a
    end


    html_template_file_name = "#{Rails.root}/app/views/survey_mailer/push_email.html.erb"
    text_template_file_name = "#{Rails.root}/app/views/survey_mailer/push_email.text.erb"
    html_template = ERB.new(File.new(html_template_file_name).read, nil, "%")
    text_template = ERB.new(File.new(text_template_file_name).read, nil, "%")
    premailer = Premailer.new(html_template.result(binding), :warn_level => Premailer::Warnings::SAFE)

    @group_emails.each_with_index do |emails, i|
      data = {}
      data[:domain] = Rails.application.config.survey_email_domain
      data[:from] = @@survey_email_from
      data[:html] = premailer.to_inline_css
      data[:text] = text_template.result(binding)
      data[:subject] = "邀请您参加问卷调查"
      data[:subject] += " --- to #{@group_emails.flatten.length} emails" if Rails.env != "production" 
      data[:to] = Rails.env == "production" ? emails.join(', ') : @@test_email
      # data[:to] = emails.join(', ')
      data[:'recipient-variables'] = @group_recipient_variables[i].to_json
      self.send_message(data)
    end
  end

  def self.welcome_email(user, protocol_hostname, callback)
    @user = user
    activate_info = {"email" => user.email, "time" => Time.now.to_i}
    @activate_link = "#{protocol_hostname}#{callback}?key=" + CGI::escape(Encryption.encrypt_activate_key(activate_info.to_json))
    result = MongoidShortener.generate(@activate_link)
    @activate_link = "#{protocol_hostname}/#{result}" if result.present?
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

  def self.newsletter(newsletter, content_html, protocol_hostname, callback, test_emails = nil)
    count = 0
    emails = []
    data = {}

    data[:domain] = Rails.application.config.user_email_domain
    data[:from] = @@user_email_from
    @content_html = content_html
    html_template_file_name = "#{Rails.root}/app/views/newsletter_mailer/news_email.html.erb"
    text_template_file_name = "#{Rails.root}/app/views/newsletter_mailer/news_email.text.erb"
    html_template = ERB.new(File.new(html_template_file_name).read, nil, "%")
    text_template = ERB.new(File.new(text_template_file_name).read, nil, "%")
    premailer = Premailer.new(html_template.result(binding), :warn_level => Premailer::Warnings::SAFE)

    data[:html] = premailer.to_inline_css
    data[:text] = text_template.result(binding)
    data[:subject] = newsletter.title || newsletter.subject
    Subscriber.all.each do |subscriber|
      if count < 990
        count += 1
        emails << subscriber.email
      else
        emails << subscriber.email
        data[:'recipient-variables'] = {
          subscriber.email =>{
            :id => subscriber._id
          }}.to_json
        if Rails.env == "production"
          data[:to] = emails.join(',')
          self.send_message(data)
        else
          data[:to] =  test_emails || @@test_email
          self.send_message(data)
          break
        end
      end
    end
  end

  def self.change_email(user, protocol_hostname, callback)
    @user = user
    activate_info = {"user_id" => user.id, "email_to_be_changed" => user.email_to_be_changed, "time" => Time.now.to_i}
    @activate_link = "#{protocol_hostname}#{callback}?key=" + CGI::escape(Encryption.encrypt_activate_key(activate_info.to_json))
    result = MongoidShortener.generate(@activate_link)
    @activate_link = "#{protocol_hostname}/#{result}" if result.present?
    data = {}
    data[:domain] = Rails.application.config.user_email_domain
    data[:from] = @@user_email_from

    html_template_file_name = "#{Rails.root}/app/views/user_mailer/change_email.html.erb"
    text_template_file_name = "#{Rails.root}/app/views/user_mailer/change_email.text.erb"
    html_template = ERB.new(File.new(html_template_file_name).read, nil, "%")
    text_template = ERB.new(File.new(text_template_file_name).read, nil, "%")
    premailer = Premailer.new(html_template.result(binding), :warn_level => Premailer::Warnings::SAFE)
    data[:html] = premailer.to_inline_css
    data[:text] = text_template.result(binding)

    data[:subject] = "更换账户邮箱"
    data[:subject] += " --- to #{user.email_to_be_changed}" if Rails.env != "production" 
    data[:to] = Rails.env == "production" ? user.email_to_be_changed : @@test_email
    self.send_message(data)
  end

  def self.find_password_email(user, protocol_hostname, callback)
    @user = user
    password_info = {"email" => user.email, "time" => Time.now.to_i}
    @password_link = "#{protocol_hostname}#{callback}?key=" + CGI::escape(Encryption.encrypt_activate_key(password_info.to_json))
    result = MongoidShortener.generate(@password_link)
    @password_link = "#{protocol_hostname}/#{result}" if result.present?
    data = {}
    data[:domain] = Rails.application.config.user_email_domain
    data[:from] = @@user_email_from

    html_template_file_name = "#{Rails.root}/app/views/user_mailer/find_password_email.html.erb"
    text_template_file_name = "#{Rails.root}/app/views/user_mailer/find_password_email.text.erb"
    # puts "=============================?????"
    # puts html_template_file_name
    html_template = ERB.new(File.new(html_template_file_name).read, nil, "%")
    # puts html_template
    # puts "=============================?????"
    text_template = ERB.new(File.new(text_template_file_name).read, nil, "%")
    # puts text_template
    # puts "=============================?????"
    premailer = Premailer.new(html_template.result(binding), :warn_level => Premailer::Warnings::SAFE)
    # puts "=============================?????1"
    data[:html] = premailer.to_inline_css
    # puts data[:html]
    # puts "=============================?????2"
    data[:text] = text_template.result(binding)
    # puts data[:text]
    # puts "=============================?????3"

    data[:subject] = "找回密码"
    data[:subject] += " --- to #{user.email}" if Rails.env != "production" 
    data[:to] = Rails.env == "production" ? user.email : @@test_email
    self.send_message(data) 
  end

  def self.rss_subscribe_email(user, protocol_hostname, callback)
    @user = user
    activate_info = {"email" => user.email, "time" => Time.now.to_i}
    @activate_link = "#{protocol_hostname}#{callback}?key=" + CGI::escape(Encryption.encrypt_activate_key(activate_info.to_json))
    result = MongoidShortener.generate(@activate_link)
    @activate_link = "#{protocol_hostname}/#{result}" if result.present?
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

  def self.send_emagzine(subject, send_from, domain, content, attachment, emails)
    group_size = 900
    @group_emails = []
    @group_recipient_variables = []
    @emails = emails

    while @emails.length >= group_size
      temp_emails = @emails[0..group_size-1]
      @group_emails << temp_emails
      @emails = @emails[group_size..-1]
      temp_recipient_variables = {}
      temp_emails.each do |e|
        temp_recipient_variables[e] = {"email" => e}
      end
      @group_recipient_variables << temp_recipient_variables
    end
    @group_emails << @emails
    temp_recipient_variables = {}
    @emails.each do |e|
      temp_recipient_variables[e] = {"email" => e}
    end
    @group_recipient_variables << temp_recipient_variables

    @group_emails.each_with_index do |emails, i|
      data = {}
      data[:domain] = domain
      data[:from] = send_from
      data[:html] = content
      data[:text] = ""
      data[:attachment] = File.new(attachment) if attachment.present?
      data[:subject] = subject
      data[:subject] += " --- to #{@group_emails.flatten.length} emails" if Rails.env != "production" 
      data[:to] = Rails.env == "production" ? emails.join(', ') : @@test_email
      data[:'recipient-variables'] = @group_recipient_variables[i].to_json
      self.send_message(data)
    end
  end

  def self.send_message(data)
    # domain = data.delete(:domain)
    domain = data[:domain]
    begin
      retval = RestClient.post("https://api:#{Rails.application.config.mailgun_api_key}"\
        "@api.mailgun.net/v2/#{domain}/messages", data)
      retval = JSON.parse(retval)
      return retval["id"]
    rescue
      return -1
    end
  end
end
