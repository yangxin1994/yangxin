#encoding: utf-8
require 'encryption'
require 'error_enum'
require 'tool'
#Corresponding to the User collection in database. Record the user information and activities related to the usage of OopsData system.
class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::ValidationsExt
  field :email, :type => String
  field :username, :type => String
  field :password, :type => String
  # 0 unregistered
  # 1 registered but not activated
  # 2 registered, activated, but not signed in
  # 3, 4, ... 用户首次登录后，需要填写一些个人信息，状态可以记录用户填写个人信息到了哪一步，以便用户填写过程中关闭浏览器，再次打开后可以继续填写
  # -1 deleted
  field :status, :type => Integer, default: 0
  field :registered_at, :type => Integer, default: 0
  # true: the user is locked and cannot login
  field :lock, :type => Boolean, default: false
  field :last_login_time, :type => Integer
  field :last_login_ip, :type => String
  field :last_login_client_type, :type => String
  field :login_count, :type => Integer, default: 0
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
  field :role, :type => Integer, default: 0
  # 0 normal users
  # 1 in the white list
  # 2 in the black list
  field :color, :type => Integer, default: 0
  field :auth_key, :type => String
  field :auth_key_expire_time, :type => Integer
  field :level, :type => Integer, default: 0
  field :level_expire_time, :type => Integer, default: -1

  field :birthday, :type => Integer, default: -1
  field :gender, :type => Boolean
  field :address, :type => String
  field :postcode, :type => String
  field :phone, :type => String
  field :full_name, :type => String
  field :identity_card, :type => String
  field :company, :type => String

  field :bankcard_number, :type => String
  field :bank, :type => String
  field :alipay_account, :type => String

  has_and_belongs_to_many :messages, class_name: "Message", inverse_of: :receiver
  has_many :sended_messages, :class_name => "Message", :inverse_of => :sender

  #################################
  # QuillMe
  field :point, :type => Integer, :default => 0
  has_many :reward_logs, :class_name => "RewardLog", :inverse_of => :user
  has_many :orders, :class_name => "Order"
  has_many :lottery_codes
  # QuillAdmin
  has_many :operate_orders, :class_name => "Order", :foreign_key => "operator_id"
  has_many :operate_reward_logs, :class_name => "RewardLog", :inverse_of => :operator,:foreign_key => "operator_id"

  #before_save :set_updated_at
  #before_update :set_updated_at

  # add role, full_name to create system_user
  # attr_accessible :email, :username, :password, :registered_at, :introducer_id, :role, :full_name, :status
  attr_protected :role, :status, :level

  has_many :third_party_users
  has_many :surveys
  has_many :groups
  has_many :materials
  has_many :public_notices
  has_many :question_feedbacks, class_name: "Feedback", inverse_of: :question_user
  has_many :answer_feedbacks, class_name: "Feedback", inverse_of: :answer_user
  has_many :faqs
  has_many :advertisements


  has_many :email_histories
  # has_many :answers
  has_many :answers, class_name: "Answer", inverse_of: :user
  has_many :template_question_answers
  has_many :survey_spreads

  has_and_belongs_to_many :answer_auditor_allocated_surveys, class_name: "Survey", inverse_of: :answer_auditors
  has_and_belongs_to_many :entry_clerk_allocated_surveys, class_name: "Survey", inverse_of: :entry_clerks
  has_many :interviewer_tasks

  has_many :reviewed_answers, class_name: "Answer", inverse_of: :auditor

  scope :unregistered, where(status: 0)

  POINT_TO_INTRODUCER = 10

  index({ email: 1 }, { background: true } )
  index({ full_name: 1 }, { background: true } )
  index({ color: 1, status: 1, role: 1 }, { background: true } )
  index({ status: 1 }, { background: true } )
  index({ introducer_id: 1, status: 1 }, { background: true } )

  private
  def set_updated_at
    self.updated_at = Time.now.to_i
  end


  public
  #*description*: Find a user given an email, username and user id. Deleted users are not included.
  #
  #*params*:
  #* email / username / user_id of the user
  #
  #*retval*:
  #* the user instance: when the user exists
  #* nil: when the user does not exist
  def self.find_by_email_username(email_username)
    user = User.where(:email => email_username, :status.gt => -1)[0]
    user = User.where(:username => email_username, :status.gt => -1)[0] if user.nil?
    return user
  end

  def self.find_by_email(email)
    return nil if email.blank?
    return User.where(:email => email.downcase, :status.gt => -1).first
  end

  def self.find_by_username(username)
    return User.where(:username => username, :status.gt => -1).first
  end

  def self.find_by_id(user_id)
    return User.where(:_id => user_id, :status.gt => -1).first
  end

  def self.find_by_id_including_deleted(user_id)
    return User.where(:_id => user_id).first
  end

  def self.find_by_auth_key(auth_key)
    return nil if auth_key.blank?
    user = User.where(:auth_key => auth_key, :status.gt => -1)[0]
    return nil if user.nil?
    # for visitor users, auth_key_expire_time is set as -1
    if user.auth_key_expire_time > Time.now.to_i || user.auth_key_expire_time == -1
      return user
    else
      user.auth_key = nil
      user.save
      return nil
    end
  end

  def self.logout(auth_key)
    user = User.find_by_auth_key(auth_key)
    if !user.nil?
      user.auth_key = nil
      user.save
    end
  end

  def get_level_information
    return {"level" => self.level, "level_expire_time" => self.level_expire_time}
  end

  def init_basic_info(user_info)
    if self.update_basic_info(user_info)
      self.status = self.status + 1
      return self.save
    else
      return false
    end
  end

  def update_basic_info(user_info)
    self.birthday = user_info["birthday"].to_i
    self.gender = user_info["gender"].to_s == "true"
    self.address = user_info["address"]
    self.postcode = user_info["postcode"]
    self.phone = user_info["phone"]
    self.full_name = user_info["full_name"]
    self.identity_card = user_info["identity_card"]
    self.company = user_info["company"]
    return self.save
  end

  def init_attr_survey(survey_id, answer_content)
    retval Answer.create_user_attr_survey_answer(self, survey_id, answer_content)
    return retval
  end

  def skip_init_step
    self.status = self.status + 1 if self.status < 4
    return false if !self.save
    return {status: self.status}
  end


  #*description*: check whether an email has been registered as an user
  #
  #*params*:
  #* email of the user
  #
  #*retval*:
  #* true or false
  def self.user_exist_by_username?(username)
    return exists?(conditions: { username: username })
  end

  def self.user_exist_by_email?(email)
    return exists?(conditions: { email: email })
  end

  #*description*: check whether an user has activated
  #
  #*params*:
  #* email of the user
  #
  #*retval*:
  #* true or false
  def self.user_activate_by_email?(email)
    user = User.find_by_email(email)
    return !!(user && user.status == 1)
  end

  def self.user_activate_by_username?(username)
    user = User.find_by_username(username)
    return !!(user && user.status == 1)
  end

  def is_deleted
    return self.status == -1
  end

  def is_registered
    return self.status > 0
  end

  def is_activated
    return self.status > 1
  end

  def is_super_admin
    return (self.role.to_i & 32) > 0
  end

  def is_admin
    return (self.role.to_i & 16) > 0
  end

  def is_survey_auditor
    return (self.role.to_i & 8) > 0
  end

  def is_answer_auditor
    return (self.role.to_i & 4) > 0
  end

  def is_interviewer
    return (self.role.to_i & 2) > 0
  end

  def is_entry_clerk
    return (self.role.to_i & 1) > 0
  end

  #*description*: create a new user
  #
  #*params*:
  #* a user hash
  #
  #*retval*:
  #* the new user instance: when successfully created
  def self.create_new_registered_user(user, current_user, third_party_user_id, callback)
    return ErrorEnum::ILLEGAL_EMAIL if Tool.email_illegal?(user["email"])
    existing_user = self.find_by_email(user["email"])
    return ErrorEnum::EMAIL_EXIST if existing_user && existing_user.is_registered
    return ErrorEnum::WRONG_PASSWORD_CONFIRMATION if user["password"] != user["password_confirmation"]
    updated_attr = user.merge(email: user["email"].downcase,
                              password: Encryption.encrypt_password(user["password"]),
                              registered_at: Time.now.to_i,
                              status: 1)
    existing_user = User.create if existing_user.nil?
    existing_user.update_attributes(updated_attr)
    # send welcome email
    TaskClient.create_task({ task_type: "email",
                             host: "localhost",
                             port: Rails.application.config.service_port,
                             params: { email_type: "welcome", email: existing_user.email, callback: callback } })
    if !third_party_user_id.nil?
      # bind the third party user if the id is provided
      third_party_user = ThirdPartyUser.find_by_id(third_party_user_id)
      third_party_user.bind(existing_user) if !third_party_user.nil?
    end
    ImportEmail.destroy_by_email(user["email"])
    return true
  end

  def self.find_or_create_new_visitor_by_email(email)
    user = User.find_by_email(email)
    if user.nil?
      user = User.create(email: email)
      ImportEmail.destroy_by_email(email)
    end
    return user
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
  def self.activate(activate_info, client_ip, client_type)
    user = User.find_by_email(activate_info["email"])
    return ErrorEnum::USER_NOT_EXIST if user.nil?     # email account does not exist
    return ErrorEnum::ACTIVATE_EXPIRED if Time.now.to_i - activate_info["time"].to_i > OOPSDATA[RailsEnv.get_rails_env]["activate_expiration_time"].to_i    # expired
    return user.login(client_ip, client_type, false)  if user.is_activated
    user = User.find_by_email(activate_info["email"])
    user.status = 2
    user.activate_time = Time.now.to_i
    user.save
    # pay introducer points
    introducer = User.find_by_id(user.introducer_id)
    if !introducer.nil?
      RewardLog.create(:user => introducer, :type => 2, :point => POINT_TO_INTRODUCER, :invited_user_id => user._id, :cause => 1)
      # send a message to the introducer
      introducer.create_message("邀请好友注册积分奖励", "您邀请的用户#{user.email}注册激活成功，您获得了#{POINT_TO_INTRODUCER}个积分奖励。", [introducer._id])
    end
    return user.login(client_ip, client_type, false)
  end

  #*description*: user login
  #
  #*params*:
  #* email address of the user
  #* password of the user
  #* ip address of the user
  #
  #*retval*:
  #* true: when successfully login
  #* EMAIL_NOT_EXIST
  #* EMAIL_NOT_ACTIVATED
  #* WRONG_PASSWORD
  def self.login_with_email(email_username, password, client_ip, client_type, keep_signed_in, third_party_user_id)
    user = User.find_by_email(email_username)
    return ErrorEnum::USER_NOT_EXIST if user.nil?
    return ErrorEnum::USER_NOT_ACTIVATED if !user.is_activated
    return ErrorEnum::WRONG_PASSWORD if user.password != Encryption.encrypt_password(password)
    if !third_party_user_id.nil?
      # bind the third party user if the id is provided
      third_party_user = ThirdPartyUser.find_by_id(third_party_user_id)
      third_party_user.bind(user) if !third_party_user.nil?
    end
    return user.login(client_ip, client_type, keep_signed_in)
  end

  def login(client_ip, client_type, keep_signed_in=false)
    self.last_login_ip = client_ip
    self.last_login_client_type = client_type
    self.login_count = 0 if self.last_login_time.blank? || Time.at(self.last_login_time).day != Time.now.day
    return ErrorEnum::LOGIN_TOO_FREQUENT if self.login_count > OOPSDATA[RailsEnv.get_rails_env]["login_count_threshold"]
    return ErrorEnum::USER_LOCKED if self.lock
    self.login_count = self.login_count + 1
    self.last_login_time = Time.now.to_i
    self.auth_key = Encryption.encrypt_auth_key("#{self._id}&#{Time.now.to_i.to_s}")
    self.auth_key_expire_time =  keep_signed_in ? -1 : Time.now.to_i + OOPSDATA["login_keep_time"].to_i
    return false if !self.save
    return {"auth_key" => self.auth_key}
  end

  def self.login_with_auth_key(auth_key)
    user = User.find_by_auth_key(auth_key)
    return ErrorEnum::AUTH_KEY_NOT_EXIST if user.nil?
    return {"user_id" => user._id, "email" => user.email, "status" => user.status, "auth_key" => user.auth_key, "expire_at" => user.auth_key_expire_time, "role" => user.role}
  end

  #*description*: reset password for an user, used when the user forgets its password
  #
  #*params*:
  #* email address of the user
  #* new password of the user
  #
  #*retval*:
  #* true: when successfully login
  #* EMAIL_NOT_EXIST
  #* WRONG_PASSWORD_CONFIRMATION
  def self.reset_password(email, new_password, new_password_confirmation)
    user = User.find_by_email(email)
    return ErrorEnum::USER_NOT_EXIST if user.nil?      # email account does not exist
    return ErrorEnum::WRONG_PASSWORD_CONFIRMATION if new_password != new_password_confirmation
    user.password = Encryption.encrypt_password(new_password)
    return user.save
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
  def reset_password(old_password, new_password, new_password_confirmation)
    return ErrorEnum::WRONG_PASSWORD_CONFIRMATION if new_password != new_password_confirmation
    return ErrorEnum::WRONG_PASSWORD if self.password != Encryption.encrypt_password(old_password)  # wrong password
    self.password = Encryption.encrypt_password(new_password)
    return self.save
  end

  #*description*: set auth key for one user
  #
  #*params*:
  #* email address of the user
  #* the auth key to be set
  #
  #*retval*:
  def set_auth_key(user_id, auth_key)
    self.auth_key = auth_key
    return self.save
  end

  #*description*: get auth key for one user
  #
  #*params*:
  #* email address of the user
  #
  #*retval*:
  #* the auth key of the user
  def self.get_auth_key(email)
    user = User.find_by_email(email)
    if user != nil
      return user.auth_key
    else
      return ""
    end
  end
  #--
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

  def update_message(message_id, update_attrs)
    m = Message.where(_id: message_id)[0]
    return ErrorEnum::MESSAGE_NOT_FOUND unless m
    m.update_attributes(update_attrs)
    m.save
  end

  def destroy_message(message_id)
    m = Message.where(_id: message_id)[0]
    return ErrorEnum::MESSAGE_NOT_FOUND unless m
    m.destroy
  end

  def unread_messages_count
    Message.unread(last_read_messeges_time).select{ |m| (message_ids.include? m.id) or (m.type == 0)}.count
  end

  def show_messages
    self.update_attribute(:last_read_messeges_time, Time.now)
    Message.all.desc(:updated_at).select{ |m| (message_ids.include? m.id) or (m.type == 0)}
    #Message.unread(created_at).select{ |m| (message_ids.include? m.id) or (m.type == 0)}
  end

  #--
  ############### operations about point #################
  #++
  # admin inc
  def operate_point(point, cause_desc, user_id)
    u = User.find_by_id_including_deleted(user_id)
    operate_reward_logs.create(
      :point => point,
      :cause_desc => cause_desc,
      :user => u,
      :type => 2,
    :cause => 0)
  end
  #--
  ############### operations about charge #################
  #++
  #Obtain the charges of this user
  def charges
    Charge.charges_of(self.email)
  end

  #--
  # **************************************************
  # Quill AdminController
  #++

  public

  COLOR_NORMAL = 0
  COLOR_WHITE = 1
  COLOR_BLACK = -1

  #--
  # instance methods
  #++

  #--
  # class methods
  #++

  scope :normal_list, where(:color => COLOR_NORMAL, :status.gt => -1)
  scope :black_list, where(:color => COLOR_BLACK, :status.gt => -1)
  scope :white_list, where(:color => COLOR_WHITE, :status.gt => -1)
  scope :deleted_users, where(status: -1)

  def self.ids_not_in_blacklist
    return User.where(:status.gt => -1).any_of({color: 0}, {color: 1}).map { |e| e._id.to_s }
  end

  def create_user(new_user)
    return ErrorEnum::REQUIRE_ADMIN unless self.is_admin || self.is_super_admin
    return ErrorEnum::REQUIRE_SUPER_ADMIN if new_user["role"].to_s.to_i > 16 and !self.is_super_admin
    return ErrorEnum::EMAIL_EXIST if User.where(email: new_user["email"].to_s.strip).count >0
    return ErrorEnum::USERNAME_EXIST if new_user["username"].to_s.strip!="" && User.where(username: new_user["username"].to_s.strip).count >0
    new_user["password"] = "oopsdata" unless new_user["password"]
    new_user["password"] = Encryption.encrypt_password(new_user["password"])
    one_user = User.new(new_user)
    one_user.role = new_user['role'].to_i # against a case of attr restrained
    one_user.status =4 # do not need activate
    return ErrorEnum:SAVE_ERROR unless one_user.save
    return true
  end

  def update_user(attributes)
    select_attrs = %w(status birthday gender address phone postcode company identity_card username full_name)
    attributes.select!{|k,v| select_attrs.include?(k.to_s)}
    retval = self.update_attributes(attributes)
    return retval
  end

  def set_admin(admin)
    if admin == true
      self.role = self.role | 16
    else
      self.role = self.role & 47
    end
    return self.save
  end

  def set_role(role)
    return ErrorEnum::WRONG_USER_ROLE if !(0..63).to_a.include?(role)
    self.role = role
    return self.save
  end

  def set_color(color)
    return ErrorEnum::WRONG_USER_COLOR if ![-1, 0, 1].include?(color)
    self.color = color
    return self.save
  end

  def set_lock(lock)
    self.lock = lock == true
    return self.save
  end

  def remove_user
    self.status = -1
    self.save
  end

  def recover
    self.status = 4
    self.save
  end

  # def add_point(point_int)
  # 	self.point += point_int
  # 	self.save
  # end

  def change_to_system_password
    # generate rand number
    sys_pwd = 1
    while sys_pwd < 16**7 do
        sys_pwd = rand(16**8-1)
      end
      sys_pwd = sys_pwd.to_s(16)
      self.password = Encryption.encrypt_password(sys_pwd)
      if !self.save then
        return ErrorEnum::USER_SAVE_FAILED
      end
      self[:new_password] = sys_pwd
      return self
    end

    def self.list_system_user(role, lock)
      role = role.to_i & 15
      selected_users = []
      users = User.where(:role.gt => 0)
      users.each do |u|
        next if u.role & role == 0
        if !lock.nil?
          next if u.lock != lock
        end
        selected_users << u
      end
      return selected_users
    end

    def get_introduced_users
      introduced_users = User.where(:introducer_id => self._id.to_s, :status.gt => 1).desc(:created_at)
      summary_info = introduced_users.map { |u| { _id: u._id.to_s, email: u.email, registered_at: u.registered_at } }
      return summary_info
    end

    def get_survey_ids_answered
      survey_ids = self.answers.map { |e| e.survey_id.to_s }
      return survey_ids.uniq
    end
  end
