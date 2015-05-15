require 'data_type'
require 'encryption'
require 'quill_common/encryption'
require 'error_enum'
require 'tool'
require 'array'
require 'httparty'
class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::ValidationsExt
  include FindTool

  EmailRexg  = '\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z'
  MobileRexg = '^(13[0-9]|15[012356789]|18[0236789]|14[57])[0-9]{8}$' 

  DEFAULT_IMG = '/assets/avatar/small_default.png'


  VISITOR = 1
  REGISTERED = 2

  SAMPLE = 1
  CLIENT = 2
  ADMIN = 4
  ANSWER_AUDITOR = 8
  INTERVIEWER = 16
  SUPERVISOR = 32  

  field :email, :type => String
  field :email_activation, :type => Boolean, default: false
  field :email_subscribe, :type => Boolean, default: false
  field :mobile, :type => String
  field :mobile_activation, :type => Boolean, default: false
  field :mobile_subscribe, :type => Boolean, default: false
  field :password, :type => String
  # 1 unregistered
  # 2 registered
  field :status, :type => Integer, default: 1
  field :registered_at, :type => Integer, default: 0
  # true: the user is locked and cannot login
  field :lock, :type => Boolean, default: false
  field :last_login_time, :type => Integer
  field :last_login_ip, :type => String
  field :last_login_client_type, :type => String, default: 'web'
  field :login_count, :type => Integer, default: 0
  field :sms_verification_code, :type => String
  field :sms_verification_expiration_time, :type => Integer,default:  -> {(Time.now + 1.minutes).to_i }
  field :rss_verification_code, :type => String
  field :rss_verification_expiration_time, :type => Integer,default:  -> {(Time.now + 1.minutes).to_i } 
  field :email_to_be_changed, :type => String
  field :change_email_expiration_time, :type => Integer
  field :mobile_to_be_changed, :type => String
  field :change_mobile_expiration_time, :type => Integer
  field :activate_time, :type => Integer
  field :introducer_id, :type => String
  field :last_read_messeges_time, :type => Time, :default => Time.now
  # an integer in the range of [0, 63]. If converted into a binary, each digit from the most significant one indicates:
  # super admin
  # admin
  # survey auditor
  # answer auditor
  # interviewer
  # entry clerk

  # 1 for sample, 2 for client, 4 for admin, 8 for answer auditor, 16 for interviewer  32 for supervisor
  field :user_role, :type => Integer, default: 1
  field :interviewer, :type => Boolean, default: false
  field :supervisor, :type => Boolean, default: false
  field :is_block, :type => Boolean, default: false

  # 0 normal users
  # 1 in the white list
  # 2 in the black list
  field :auth_key, :type => String
  field :auth_key_expire_time, :type => Integer
  field :auth_key_remote, :type => String
  field :auth_key_remote_expire, :type => Boolean, :default => true
  field :level, :type => Integer, default: 0
  field :level_expire_time, :type => Integer, default: -1
  field :point, :type => Integer, :default => 0
  field :carnival_email_sent, :type => Boolean, default: false
  # 新浪爬虫验证码数据信息
  field :sina_verify_info,type:Hash,default:{commit:0,success:0,faild:0}

  has_and_belongs_to_many :messages, class_name: "Message", inverse_of: :receiver
  has_many :sended_messages, :class_name => "Message", :inverse_of => :sender
  has_many :orders, :class_name => "Order", :inverse_of => :sample
  # QuillAdmin
  has_many :operate_orders, :class_name => "Order", :foreign_key => "operator_id"
  has_many :third_party_users
  has_many :surveys, class_name: "Survey", inverse_of: :user
  has_many :materials
  has_one  :avatar, :class_name => "Material", :inverse_of => :user
  has_many :public_notices
  has_many :question_feedbacks, class_name: "Feedback", inverse_of: :question_user
  has_many :answer_feedbacks, class_name: "Feedback", inverse_of: :answer_user
  has_many :faqs
  has_many :advertisements
  has_many :survey_invitation_histories
  has_many :answers, class_name: "Answer", inverse_of: :user
  has_many :survey_spreads
  has_and_belongs_to_many :answer_auditor_allocated_surveys, class_name: "Survey", inverse_of: :answer_auditors
  has_many :interviewer_tasks
  has_many :reviewed_answers, class_name: "Answer", inverse_of: :auditor
  has_many :logs
  has_one  :affiliated, :class_name => "Affiliated", :inverse_of => :user
  has_many :banners, class_name: "Banner", inverse_of: :user

  scope :sample, mod(:user_role => [2, 1])

  index({ email: 1 }, { background: true } )
  index({ full_name: 1 }, { background: true } )
  index({ color: 1, status: 1, role: 1 }, { background: true } )
  index({ status: 1 }, { background: true } )
  index({ introducer_id: 1, status: 1 }, { background: true } )
  index({ auth_key: 1, status: 1 }, { background: true } )
  index({ mobile: 1 }, { background: true } )
  index({ user_role: 1 }, { background: true } )
  index({ name:1},{background: true})
  index({ created_at:1},{background: true})
  index({ is_block:1},{background: true})

  validates_numericality_of :point, :greater_than_or_equal_to => 0

  public

  def self.find_by_auth_key(auth_key)
    return nil if auth_key.blank?
    user = User.where(:auth_key => auth_key, :status.gt => -1)[0]
    return nil if user.nil?
    # for visitor users, auth_key_expire_time is set as -1
    if user.auth_key_expire_time > Time.now.to_i || user.auth_key_expire_time == -1
      return user
    else
      user.refresh_auth_key
      return nil
    end
  end

  def self.auth_remote(akr, notoken = false)
    if user = self.where(:auth_key_remote => akr).first
      unless user.auth_key_remote_expire
        user.auth_key_remote_expire = true
        user.save
        if notoken
          {token: true}
        else
          {token: QuillCommon::Encryption.encrypt_qauth_key("#{user.password}&#{Time.now.to_i.to_s}")}
        end
      end
    else
      nil
    end
  end

  def get_auth_remote_key
    if auth_key_remote_expire
      self.auth_key_remote = QuillCommon::Encryption.encrypt_qauth_key("#{self.email}&#{Time.now.to_i.to_s}")
      self.auth_key_remote_expire = false
      self.save
    end
    self.auth_key_remote 
  end

  def refresh_auth_key
    self.update_attributes(:auth_key =>nil)
  end

  #生成订阅用户并发激活码或者邮件
  def self.create_rss_user(email_mobile, callback)
    user = find_by_email_or_mobile(email_mobile)

    account = {}
    if email_mobile.match(/#{EmailRexg}/i)
      account[:email] = email_mobile.downcase     
    elsif email_mobile.match(/#{MobileRexg}/i)
      active_code = Tool.generate_active_mobile_code
      account[:mobile] = email_mobile
      account[:rss_verification_code] = active_code
      account[:rss_verification_expiration_time] = (Time.now + 2.hours).to_i
    end

    new_user = true  # default imagagine the user is a new user
    if user.present? && user.status == REGISTERED
      if email_mobile.match(/#{EmailRexg}/i)
        account[:email_subscribe] = true
      else
        account[:mobile_subscribe] = true
      end
      user.update_attributes(account)
      new_user = false    
    else
      if user.present? && email_mobile.match(/#{MobileRexg}/i)
        user.update_attributes(account)
      elsif !user.present?
        account[:registered_at] = Time.now.to_i
        account[:status] = VISITOR
        user = User.create(account)        
      end       

      if active_code.present?
        SmsWorker.perform_async("rss_subscribe", user.mobile, "", :code => active_code)
      else
        if account[:email]          
          EmailWorker.perform_async("rss_subscribe",
            user.email,
            callback[:protocol_hostname],
            callback[:path])
        end
      end     
    end   
    return {:success => true, :new_user => new_user}
  end

  #订阅邮件激活
  def self.activate_rss_subscribe(active_info)
    email = active_info['email']
    time  = active_info['time']   
    user  = User.where(:email => email).first
    return ErrorEnum::USER_NOT_EXIST if !user.present?
    return ErrorEnum::ACTIVATE_EXPIRED if Time.now.to_i - time.to_i > OOPSDATA[Rails.env]["activate_expiration_time"].to_i        
    user.update_attributes(:email_subscribe => true )
    return true
  end

  def self.create_activated_rss_user(email_mobile)
    logger.info "AAAAAAAAAAAAAAA"
    logger.info email_mobile.inspect
    user = find_by_email_or_mobile(email_mobile)

    account = {}
    if email_mobile.match(/#{EmailRexg}/i)
      account[:email] = email_mobile.downcase
      account[:email_subscribe] = true
    elsif email_mobile.match(/#{MobileRexg}/i)
      account[:mobile] = email_mobile
      account[:mobile_subscribe] = true
    end
    logger.info "BBBBBBBBBBBBBBBB"
    logger.info account.inspect

    if user.present?
      user.update_attributes(account)
    else
      account[:registered_at] = Time.now.to_i
      account[:status] = VISITOR
      user = User.create(account)        
    end   
    return {:success => true}
  end

  def self.cancel_subscribe(active_info)
    email_mobile  = active_info['email_mobile']
    mobile = active_info['mobile']
    user = User.find_by_email_or_mobile(email_mobile)
    return ErrorEnum::USER_NOT_EXIST unless user.present?
    user.update_attributes(:email_subscribe => false) if email_mobile.match(/#{EmailRexg}/i)
    user.update_attributes(:mobile_subscribe => false) if email_mobile.match(/#{MobileRexg}/i)
    return {:success => true}
  end

  def self.send_forget_pass_code(email_mobile, callback)
    sample = self.find_by_email_or_mobile(email_mobile) 
    if sample.present?
      if(email_mobile.match(/#{MobileRexg}/i))
        active_code = Tool.generate_active_mobile_code  
        sample.update_attributes(:sms_verification_code => active_code, :sms_verification_expiration_time => (Time.now + 2.hours).to_i)
        return SmsWorker.perform_async("find_password", email_mobile, "", :code => active_code)
      else
        return EmailWorker.perform_async("find_password",
          email_mobile,
          callback[:protocol_hostname],
          callback[:path])
      end
    else
      return ErrorEnum::USER_NOT_EXIST
    end
  end

  def self.forget_pass_mobile_activate(mobile,code)
    sample = self.find_by_mobile(mobile)
    if sample.present?
      return ErrorEnum::ACTIVATE_EXPIRED if Time.now.to_i  > sample.sms_verification_expiration_time
      return ErrorEnum::ACTIVATE_CODE_ERROR if sample.sms_verification_code != code
      return true
    else
      return ErrorEnum::USER_NOT_EXIST
    end
  end

  def self.generate_new_password(email_mobile,password)
    sample = self.find_by_email_or_mobile(email_mobile)    
    if sample.present?
      password = Encryption.encrypt_password(password)
      return sample.update_attributes(:password => password)
    else
      return ErrorEnum::USER_NOT_EXIST
    end
  end

  ####################################
  #opt is a hash that contains some key as follow
  #email_mobile : 要注册的手机或者邮箱
  #password:密码
  #keep_signed_in:是否记住我
  #third_party_user_id:第三方账户的id
  #callback:发送激活邮件的回调函数
  ####################################
  def self.create_new_user(opt)  
    account = {}
    if opt[:email_mobile].match(/#{EmailRexg}/i)  ## match email
      account[:email] = opt[:email_mobile].downcase
    elsif opt[:email_mobile].match(/#{MobileRexg}/i)  ## match mobile
      account[:mobile] = opt[:email_mobile]
    end

    return ErrorEnum::ILLEGAL_EMAIL_OR_MOBILE if account.blank?
    existing_user = account[:email] ? self.find_by_email(account[:email]) : self.find_by_mobile(account[:mobile])
    return ErrorEnum::USER_REGISTERED if existing_user && existing_user.is_activated
    existing_user = User.create if existing_user.nil?
    password = Encryption.encrypt_password(opt[:password]) if account[:email]
    account[:status] =  REGISTERED
    if account[:mobile].present?
      if existing_user.sms_verification_code.present? && existing_user.sms_verification_expiration_time > Time.now.to_i
        active_code = existing_user.sms_verification_code
      else
        active_code = Tool.generate_active_mobile_code
        account[:sms_verification_code] = active_code
        account[:sms_verification_expiration_time]  = (Time.now + 2.hours).to_i
      end
    end
    updated_attr = account.merge(password: password, registered_at: Time.now.to_i)
    existing_user.update_attributes(updated_attr)

    if account[:mobile].present?
      SmsWorker.perform_async("welcome", existing_user.mobile, "", :active_code => active_code)
    else
      if account[:email]
        EmailWorker.perform_async(
          "welcome", 
          existing_user.email,
          opt[:callback][:protocol_hostname],
          opt[:callback][:path]
        )
      end
    end

    if !opt[:third_party_user_id].nil?
      third_party_user = ThirdPartyUser.find_by_id(opt[:third_party_user_id])
      third_party_user.bind(existing_user) if !third_party_user.nil?
    end
    return true
  end

  #*description*: activate a user
  #
  #*params*:
  #* an activate info hash, which has the following keys
  #  - email: the email address of the user
  #  - time: the time the activat email is sent
  #
  #*retval*:
  #* true: when successfully activated or already activated
  def self.activate(activate_type, activate_info, client_ip, client_type, password = nil)
    user = User.find_by_email(activate_info["email"]) if activate_type == "email"
    user = User.find_by_mobile(activate_info["mobile"]) if activate_type == "mobile"
    return ErrorEnum::USER_NOT_EXIST if user.nil?     # email account does not exist
    if activate_type == "email"
      # email activate
      return ErrorEnum::USER_NOT_REGISTERED if user.status == VISITOR
      return ErrorEnum::ACTIVATE_EXPIRED if Time.now.to_i - activate_info["time"].to_i > OOPSDATA[Rails.env]["activate_expiration_time"].to_i    # expired
      user.email_activation = true
      user.activate_time = Time.now.to_i
      user.email_subscribe = true
    else
      # mobile activate
      #return ErrorEnum::USER_NOT_REGISTERED if user.status == VISITOR
      return ErrorEnum::ILLEGAL_ACTIVATE_KEY if user.sms_verification_code != activate_info["verification_code"]
      return ErrorEnum::ACTIVATE_EXPIRED if Time.now.to_i  > user.sms_verification_expiration_time
      user.password = Encryption.encrypt_password(activate_info["password"])
      user.mobile_activation = true
      user.activate_time = Time.now.to_i
      user.mobile_subscribe = true
    end
    user.save
    RegistLog.create_regist_log(user.id) unless RegistLog.find_by_user_id(user.id).present?
    return user.login(client_ip, client_type, false)
  end

  ####################################
  #opt is a hash that contains some key as follow
  #email_mobile : 登录用的email或mobile
  #password:密码
  #client_ip:登录ip
  #keep_signed_in:是否记住我
  #third_party_user_id:第三方登录账户的id
  ####################################
  def self.login_with_email_mobile(opt)
    user = nil
    if opt[:email_mobile].match(/#{EmailRexg}/i)  ## match email
      user = User.find_by_email(opt[:email_mobile].downcase)
    elsif opt[:email_mobile].match(/#{MobileRexg}/i)  ## match mobile
      user = User.find_by_mobile(opt[:email_mobile])
    end

    return ErrorEnum::USER_NOT_EXIST unless user.present?
    return ErrorEnum::USER_NOT_REGISTERED if user.status == VISITOR
    return ErrorEnum::USER_NOT_ACTIVATED unless user.is_activated
    return ErrorEnum::WRONG_PASSWORD if user.password != Encryption.encrypt_password(opt[:password])
    if opt[:third_party_user_id].present?
      third_party_user = ThirdPartyUser.find_by_id(opt[:third_party_user_id])
      third_party_user.bind(user) if third_party_user.present?
    end
    return user.login(opt[:client_ip], opt[:client_type], opt[:keep_signed_in])
  end


  def self.search_sample(email, mobile, is_block)
    samples = User
    # samples = User.sample
    samples = samples.where(:is_block => false) if !is_block
    samples = samples.where(:email => /#{email.to_s}/) if !email.blank?
    samples = samples.where(:mobile => /#{mobile.to_s}/) if !mobile.blank?
    return samples
  end

  def self.count_sample(period, time_length)
    normal_sample_number = User.sample.where(:is_block => false).length
    block_sample_number = User.sample.where(:is_block => true).length
    seconds_per_period_ary = {"year" => 1.years.to_i,
      "month" => 1.months.to_i,
      "week" => 1.weeks.to_i,
      "day" => 1.days.to_i}
    seconds_per_period = seconds_per_period_ary.has_key?(period) ? seconds_per_period_ary[period] : 1.months.to_i
    time_duration = time_length * seconds_per_period
    start_time = Time.at(Time.now.to_i - time_duration)
    new_samples = User.sample.where(:created_at.gt => start_time)
    time_point_ary = (0..time_length-1).to_a
    time_point_ary.map! { |e| e * seconds_per_period + start_time.to_i}
    new_sample_number = []
    time_point_ary.each do |time_point|
      new_sample_number << User.sample.and(:created_at.gte => Time.at(time_point), :created_at.lt => Time.at(time_point + seconds_per_period)).length
    end
    return {"normal_sample_number" => normal_sample_number,
      "block_sample_number" => block_sample_number,
      "new_sample_number" => new_sample_number}
  end

  def self.count_active_sample(period, time_length)
    seconds_per_period_ary = {"year" => 1.years.to_i,
      "month" => 1.months.to_i,
      "week" => 1.weeks.to_i,
      "day" => 1.days.to_i}
    seconds_per_period = seconds_per_period_ary.has_key?(period) ? seconds_per_period_ary[period] : 1.months.to_i
    time_duration = time_length * seconds_per_period
    start_time = Time.at(Time.now.to_i - time_duration)
    time_point_ary = (0..time_length-1).to_a
    time_point_ary.map! { |e| e * seconds_per_period + start_time.to_i}
    active_sample_number = []
    time_point_ary.each do |time_point|
      logs = Log.where(:created_at.gte => Time.at(time_point), :created_at.lt => Time.at(time_point + seconds_per_period))
      active_sample_number << logs.map {|e| e.user_id}.uniq.length
    end
    return active_sample_number
  end

  def self.make_sample_attribute_statistics(sample_attribute)
    name = sample_attribute.name.to_sym
    analyze_requirement = sample_attribute.analyze_requirement
    # completion = 100 - User.where(name => nil).length * 100 / User.all.length
    analyze_result = {}
    case sample_attribute.type
    when DataType::ENUM
      registered_users = Array.new(sample_attribute.enum_array.length) { 0 }
      all_users = Array.new(sample_attribute.enum_array.length) { 0 }
      users_with_answers = Array.new(sample_attribute.enum_array.length) { 0 }
      User.all.each do |u|
        attribute = u.read_sample_attribute(name)
        next if attribute.blank? || attribute >= sample_attribute.enum_array.length
        all_users[attribute] += 1
        registered_users[attribute] += 1 if u.status == REGISTERED
        users_with_answers[attribute] += 1 if u.answers.present?
      end
      analyze_result["all_users"] = all_users
      analyze_result["registered_users"] = registered_users
      analyze_result["users_with_answers"] = users_with_answers
    when DataType::ARRAY
      registered_users = Array.new(sample_attribute.enum_array.length) { 0 }
      all_users = Array.new(sample_attribute.enum_array.length) { 0 }
      users_with_answers = Array.new(sample_attribute.enum_array.length) { 0 }
      User.all.each do |u|
        attribute = u.read_sample_attribute(name)
        next if attribute.blank?
        attribute.each do |e|
          next if e >= sample_attribute.enum_array.length
          all_users[e] += 1
          registered_users[e] += 1 if u.status == REGISTERED
          users_with_answers[e] += 1 if u.answers.present?
        end
      end
      analyze_result["all_users"] = all_users
      analyze_result["registered_users"] = registered_users
      analyze_result["users_with_answers"] = users_with_answers
    when DataType::ADDRESS
      registered_users = QuillCommon::AddressUtility.province_hash
      all_users = QuillCommon::AddressUtility.province_hash
      users_with_answers = QuillCommon::AddressUtility.province_hash
      provinces = QuillCommon::AddressUtility.province_hash.keys
      User.all.each do |u|
        attribute = u.read_sample_attribute(name)
        provinces.each do |p|
          if QuillCommon::AddressUtility.satisfy_region_code?(attribute, p)
            all_users[p]["count"] += 1
            registered_users[p]["count"] += 1 if u.status == REGISTERED
            users_with_answers[p]["count"] += 1 if u.answers.present?
            break
          end
        end
      end
      analyze_result["all_users"] = all_users
      analyze_result["registered_users"] = registered_users
      analyze_result["users_with_answers"] = users_with_answers
    when DataType::NUMBER
      segmentation = analyze_requirement["segmentation"] || []
      all_users_data = []
      registered_users_data = []
      users_with_answers_data = []
      User.all.each do |u|
        attribute = u.read_sample_attribute(name)
        next if attribute.blank?
        all_users_data << attribute
        registered_users_data << attribute if u.status == REGISTERED
        users_with_answers_data << attribute if u.answers.present?
      end
      analyze_result["all_users"] = Tool.calculate_segmentation_distribution(segmentation, all_users_data)
      analyze_result["registered_users"] = Tool.calculate_segmentation_distribution(segmentation, registered_users_data)
      analyze_result["users_with_answers"] = Tool.calculate_segmentation_distribution(segmentation, users_with_answers_data)
    when DataType::NUMBER_RANGE
      segmentation = analyze_requirement["segmentation"] || []
      all_users_data = []
      registered_users_data = []
      users_with_answers_data = []
      User.all.each do |u|
        attribute = u.read_sample_attribute(name)
        next if attribute.blank?
        all_users_data << attribute.mean
        registered_users_data << attribute.mean if u.status == REGISTERED
        users_with_answers_data << attribute.mean if u.answers.present?
      end
      analyze_result["all_users"] = Tool.calculate_segmentation_distribution(segmentation, all_users_data)
      analyze_result["registered_users"] = Tool.calculate_segmentation_distribution(segmentation, registered_users_data)
      analyze_result["users_with_answers"] = Tool.calculate_segmentation_distribution(segmentation, users_with_answers_data)
    when DataType::DATE
      segmentation = analyze_requirement["segmentation"] || []
      all_users_data = []
      registered_users_data = []
      users_with_answers_data = []
      User.all.each do |u|
        attribute = u.read_sample_attribute(name)
        next if attribute.blank?
        all_users_data << attribute
        registered_users_data << attribute if u.status == REGISTERED
        users_with_answers_data << attribute if u.answers.present?
      end
      analyze_result["all_users"] = Tool.calculate_segmentation_distribution(segmentation, all_users_data)
      analyze_result["registered_users"] = Tool.calculate_segmentation_distribution(segmentation, registered_users_data)
      analyze_result["users_with_answers"] = Tool.calculate_segmentation_distribution(segmentation, users_with_answers_data)
    when DataType::DATE_RANGE
      segmentation = analyze_requirement["segmentation"] || []
      all_users_data = []
      registered_users_data = []
      users_with_answers_data = []
      User.all.each do |u|
        attribute = u.read_sample_attribute(name)
        next if attribute.blank?
        all_users_data << attribute.mean
        registered_users_data << attribute.mean if u.status == REGISTERED
        users_with_answers_data << attribute.mean if u.answers.present?
      end
      analyze_result["all_users"] = Tool.calculate_segmentation_distribution(segmentation, all_users_data)
      analyze_result["registered_users"] = Tool.calculate_segmentation_distribution(segmentation, registered_users_data)
      analyze_result["users_with_answers"] = Tool.calculate_segmentation_distribution(segmentation, users_with_answers_data)
    end
    return analyze_result
  end

  def mini_avatar
    md5 = Digest::MD5.hexdigest(self.id)
    return "/uploads/avatar/mini_#{md5}.png" if File.exist?("#{Rails.root}/public/uploads/avatar/mini_#{md5}.png")
    %w( mini small thumb).each do |ver|
      return "/uploads/avatar/#{ver}_#{md5}.png" if File.exist?("#{Rails.root}/public/uploads/avatar/#{ver}_#{md5}.png")  
    end
    return "/assets/avatar/mini_default.png"  
  end

  def set_receiver_info(receiver_info)
    if self.affiliated.present?
      self.affiliated.update_attributes(:receiver_info => receiver_info)
    else
      self.create_affiliated(:receiver_info => receiver_info)
    end   
    return true
  end

  #收获地址完善度
  def receiver_completed_info
    info = self.affiliated.try(:receiver_info)
    return 0 unless info.present?
    attr_length = self.affiliated.receiver_info.length
    complete = 0
    self.affiliated.receiver_info.each_pair do |k,v|
      if k == 'address'
        complete += 1 if v. != -1  
      else
        complete += 1 if v.present?
      end
    end
    return complete * 100 / attr_length
  end

  def is_activated
    return self.mobile_activation || self.email_activation
  end

  def is_admin?
    return (self.user_role.to_i & ADMIN) > 0
  end

  def is_answer_auditor?
    return (self.user_role.to_i & ANSWER_AUDITOR) > 0
  end

  def is_interviewer?
    return (self.user_role.to_i & INTERVIEWER) > 0
  end

  def is_supervisor?
    return true if self.user_role.to_i == SUPERVISOR || [4,5,7].include?(self.user_role.to_i)
    return false
  end

  def make_mobile_rss_activate(code)
    return ErrorEnum::ACTIVATE_EXPIRED if Time.now.to_i  > self.rss_verification_expiration_time
    return ErrorEnum::ACTIVATE_CODE_ERROR if self.rss_verification_code != code
    return self.update_attributes(:mobile_subscribe => true)
  end

  def completed_info
    affiliated = self.affiliated
    if affiliated
      complete = 0
      affiliated.attributes.each_key do |attr_name|
        if SampleAttribute::BASIC_ATTR.include?(attr_name)
          complete += 1
        end 
      end
      basic_attr = SampleAttribute::BASIC_ATTR.length
      return complete * 100 / basic_attr
    else
      return 0 
    end
  end

  def change_email(client_ip)
    return ErrorEnum::ACTIVATE_EXPIRED if Time.now.to_i > change_email_expiration_time
    self.email = self.email_to_be_changed
    self.email_activation = true
    return self.login(client_ip, nil, false)
  end

  def login(client_ip, client_type, keep_signed_in=false)
    self.last_login_ip = client_ip
    self.last_login_client_type = client_type
    self.login_count = 0 if self.last_login_time.blank? || Time.at(self.last_login_time).day != Time.now.day
    return ErrorEnum::LOGIN_TOO_FREQUENT if self.login_count > OOPSDATA[Rails.env]["login_count_threshold"]
    return ErrorEnum::USER_LOCKED if self.is_block
    self.login_count = self.login_count + 1
    self.last_login_time = Time.now.to_i
    self.auth_key = Encryption.encrypt_auth_key("#{self._id}&#{Time.now.to_i.to_s}")
    self.auth_key_expire_time =  keep_signed_in ? -1 : Time.now.to_i + OOPSDATA["login_keep_time"].to_i
    return false if !self.save
    return {"auth_key" => self.auth_key}
  end


  #*description*: reset password for an user, used when the user resets its password
  #
  #*params*:
  #* old password of the user
  #* new password of the user
  #
  #*retval*:
  #* true: when successfully login
  #* WRONG_PASSWORD
  def reset_password(old_password, new_password)
    return ErrorEnum::WRONG_PASSWORD if self.password != Encryption.encrypt_password(old_password)  # wrong password
    self.password = Encryption.encrypt_password(new_password)
    return self.save
  end


  ############### operations about message#################
  #++
  #ctreate
  def create_message(title, content, receiver = [])
    m = sended_messages.create(:title => title, :content => content, :type => 0) if receiver.size == 0
    m = sended_messages.create(:title => title, :content => content, :type => 1) if receiver.size >= 1
    return m unless m.is_a? Message
    receiver.each do |r|
      u = User.find_by_email(r.to_s) || User.find_by_id(r)
      next unless u
      u.messages << m# => unless m.created_at.nil?
      u.save
    end
    m
  end

  def unread_messages_count
    Message.unread(last_read_messeges_time).select{ |m| (message_ids.include? m.id) or (m.type == 0)}.count
  end

  #--
  ############### operations about point #################
  #++
  # admin inc
  def operate_point(amount, remark)
    self.point += amount.to_i
    PointLog.create_admin_operate_point_log(amount, remark, self._id) if self.save
  end



  def set_sample_role(role)
    self.user_role = role.sum
    self.interviewer = self.user_role & 0x10 > 0
    return self.save
  end

  def set_password_when_nil(password)
    self.update_attributes(:password => Encryption.encrypt_password(password)) if self.password.blank? && password.present?
  end

  # 我推广的问卷数
  def spread_count
    Answer.my_spread(self.id).finished.size
  end

  # 我回答的问卷数
  def answer_count
    self.answers.not_preview.size
  end


  def block(block)
    self.is_block = block.to_s == "true"
    return self.save
  end


  def sample_attributes
    sample = {
      "email" => self.email,
      "mobile" => self.mobile
    }
    SampleAttribute.normal.each do |s|
      sample[s.name] = self.read_sample_attribute(s.name)
    end
    return sample
  end

  def need_update_attribute(attr_name, updated_value)
    sa = SampleAttribute.normal.find_by_name(attr_name)
    # binding.pry
    return false if sa.nil?
    return true if ![DataType::NUMBER_RANGE, DataType::DATE_RANGE].include?(sa.type)
    sa_value = self.read_sample_attribute(attr_name)
    return true if sa_value.nil?
    return false if Tool.range_compare(sa_value, updated_value) == -1
    return true
  end

  def read_sample_attribute(name)
    sa = SampleAttribute.normal.find_by_name(name)
    return nil if sa.nil?
    return nil if self.affiliated.nil?
    return self.affiliated.read_attribute(sa.name.to_sym)
  end

  def read_sample_attribute_by_id(sa_id)
    sa = SampleAttribute.normal.find_by_id(sa_id)
    return nil if sa.nil?
    return nil if self.affiliated.nil?
    return self.affiliated.read_attribute(sa.name.to_sym)
  end

  def write_sample_attribute(name, value)
    sa = SampleAttribute.normal.find_by_name(name)
    return false if sa.nil?
    self.create_affiliated if self.affiliated.nil?
    self.affiliated.write_attribute(sa.name.to_sym, value)
    return self.affiliated.save
  end


  def get_basic_attributes
    basic_attributes = {}
    SampleAttribute::BASIC_ATTR.each do |attr_name|
      basic_attributes[attr_name] = self.read_sample_attribute(attr_name)
    end
    return basic_attributes
  end

  def set_basic_attributes(basic_attributes)
    basic_attributes.each do |attr_name, attr_value|
      next if !SampleAttribute::BASIC_ATTR.include?(attr_name)
      if self.need_update_attribute(attr_name, attr_value)
        self.write_sample_attribute(attr_name, attr_value)
      end
    end
    return true
  end

  def nickname
    nickname = self.read_sample_attribute("nickname")
    if nickname.nil?
      nickname = self.email.split('@')[0] if !self.email.blank?
      nickname ||= self.mobile
    end
    return nickname
  end

  # 获取新浪微博爬虫的验证码图片
  def get_verify_code
    ip_arr = ['123.56.95.229']
    ip     = ip_arr.sample
    retval = HTTParty.get("http://#{ip}:3000/captchas.json")
    hash   = JSON.parse(retval.body).first
    return {url:hash['img_url'],id:hash['cid'],ip:ip}
  end
  # 用户每输入正确一个新浪微博爬虫的验证码就奖励一积分
  def add_verify_code_reward(opt)
    self.sina_verify_info[:commit] += 1
    self.save
    result = HTTParty.post("http://#{opt[:ip]}:3000/captchas",:query => { :code => opt[:code],:id => opt[:cid]})
    body   = JSON.parse(result.body)
    if body
      self.point += 1 
      self.sina_verify_info[:success] += 1
      self.save
      sid        = self.id.to_s
      PointLog.create_weibo_verify_code_log(1,sid)
    else
      self.sina_verify_info[:faild] += 1
      self.save
    end
  end

  def verify_judge_count
    sina_verify_info[:commit].to_i -  sina_verify_info[:success].to_i - sina_verify_info[:faild].to_i
  end

  def self.clear_users
    time = Time.now
    User.where(:updated_at.lt => time).each_with_index do |u, i|
      puts i if i%1000 == 0
      if u.answers.length == 0 && u.status == User::VISITOR && u.email_subscribe == false && u.mobile_subscribe == false
        u.logs.destroy_all
        u.destroy
      end
    end
  end
end
