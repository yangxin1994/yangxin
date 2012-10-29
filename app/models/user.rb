# encoding: utf-8
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
# true: the user is locked and cannot login
	field :lock, :type => Boolean, default: false
	field :last_login_time, :type => Integer
	field :last_login_ip, :type => String
	field :last_login_client_type, :type => String
	field :login_count, :type => Integer, default: 0
	field :activate_time, :type => Integer
	field :introducer_id, :type => Integer
	field :introducer_to_pay, :type => Float
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


	has_and_belongs_to_many :messages, class_name: "Message", inverse_of: :receiver
	has_many :sended_messages, :class_name => "Message", :inverse_of => :sender

	#################################
	# QuillMe
	field :point, :type => Integer
	has_many :point_logs, :class_name => "PointLog", :inverse_of => :user
	has_many :orders, :class_name => "Order"
	has_many :lottery_codes
	# QuillAdmin
	has_many :operate_orders, :class_name => "Order", :foreign_key => "operated_admin_id"
	has_many :operate_point_logs, :class_name => "PointLog", :inverse_of => :operated_admin,:foreign_key => "operated_admin_id"	

	#before_save :set_updated_at
	#before_update :set_updated_at

	attr_accessible :email, :username, :password, :registered_at

	has_many :surveys
	has_many :groups
	has_many :materials
	has_many :public_notices
	has_many :question_feedbacks, class_name: "Feedback", inverse_of: :question_user
	has_many :answer_feedbacks, class_name: "Feedback", inverse_of: :answer_user
	has_many :faqs
	has_many :advertisements


	has_many :email_histories
	has_many :answers
	has_many :template_question_answers

	scope :unregistered, where(status: 0)
	scope :receive_email_user

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
		return User.where(:email => email, :status.gt => -1).first
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
		return self.status
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
		return self.role & 32 > 0
	end

	def is_admin
		return self.role & 16 > 0
	end

	def is_survey_auditor
		return self.role & 8 > 0
	end

	def is_answer_auditor
		return self.role & 4 > 0
	end

	def is_interviewer
		return self.role & 2 > 0
	end

	def is_entry_clerk
		return self.role & 1 > 0
	end

	#*description*: create a new user
	#
	#*params*:
	#* a user hash
	#
	#*retval*:
	#* the new user instance: when successfully created
	def self.create_new_registered_user(user, current_user)
    logger.debug user.inspect
		# check whether the email acount is illegal
		return ErrorEnum::ILLEGAL_EMAIL if Tool.email_illegal?(user["email"])
		return ErrorEnum::EMAIL_EXIST if self.user_exist_by_email?(user["email"])
		return ErrorEnum::USERNAME_EXIST if self.user_exist_by_username?(user["username"])
		return ErrorEnum::WRONG_PASSWORD_CONFIRMATION if user["password"] != user["password_confirmation"]
		updated_attr = user.merge("password" => Encryption.encrypt_password(user["password"]), "registered_at" => Time.now.to_i)
		if !current_user.nil?
			current_user.attributes = updated_attr
		else
			current_user = User.new(updated_attr)
		end
		# set the current user's status as registered but not activated
		current_user.status = 1
		current_user.save
		return current_user
	end

	def self.create_new_visitor_user
		user = User.new
		user.auth_key = Encryption.encrypt_auth_key("#{user.id}&#{Time.now.to_i.to_s}")
		user.auth_key_expire_time = -1
		user.save
		return user.auth_key
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
	def self.activate(activate_info)
		user = User.find_by_email(activate_info["email"])
		return ErrorEnum::USER_NOT_EXIST if user.nil?     # email account does not exist
		return true  if user.is_activated
		return ErrorEnum::ACTIVATE_EXPIRED if Time.now.to_i - activate_info["time"].to_i > OOPSDATA[RailsEnv.get_rails_env]["activate_expiration_time"].to_i    # expired
		user = User.find_by_email(activate_info["email"])
		user.status = 2
		user.activate_time = Time.now.to_i
		return user.save
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
	def self.login(email_username, password, client_ip, client_type, keep_signed_in)
		user = User.find_by_email_username(email_username)
		return ErrorEnum::USER_NOT_EXIST if user.nil?
		# There is no is_activated
		return ErrorEnum::USER_NOT_ACTIVATED if !user.is_activated
		return ErrorEnum::WRONG_PASSWORD if user.password != Encryption.encrypt_password(password)
		# record the login information
		user.last_login_ip = client_ip
		user.last_login_client_type = client_type
		user.login_count = 0 if user.last_login_time.blank? || Time.at(user.last_login_time).day != Time.now.day
		return ErrorEnum::LOGIN_TOO_FREQUENT if user.login_count > OOPSDATA[RailsEnv.get_rails_env]["login_count_threshold"]
		user.login_count = user.login_count + 1
		user.last_login_time = Time.now.to_i
		user.auth_key = Encryption.encrypt_auth_key("#{user.id}&#{Time.now.to_i.to_s}")
		user.auth_key_expire_time =  keep_signed_in ? -1 : Time.now.to_i + OOPSDATA["login_keep_time"].to_i
		return false if !user.save
		return {"status" => user.status, "auth_key" => user.auth_key, "user_id" => user._id.to_s}
	end

	def self.login_with_auth_key(auth_key)
		user = User.find_by_auth_key(auth_key)
		return ErrorEnum::AUTH_KEY_NOT_EXIST if user.nil?
		return {"status" => user.status, "auth_key" => user.auth_key, "expire_at" => user.auth_key_expire_time, "role" => user.role}
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
		return ErrorEnum::USER_NOT_EXIST if user_exist_by_email?(email) == false      # email account does not exist
		return ErrorEnum::WRONG_PASSWORD_CONFIRMATION if new_password != new_password_confirmation
		user = User.find_by_email(email)
		user.password = Encryption.encrypt_password(new_password)
		user.save
		return true
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
		self.save
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
			u = User.find_by_email(r) || User.find_by_id(r)
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
		Message.all.select{ |m| (message_ids.include? m.id) or (m.type == 0)}
		#Message.unread(created_at).select{ |m| (message_ids.include? m.id) or (m.type == 0)}
	end

#--
############### operations about point #################
#++
# admin inc
	def operate_point(operated_point, user_id)
		u = User.find_by_id(user_id)
		operate_point_logs.create(:operated_point => operated_point,
															:user => u,
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
############### operations about third party user #################
#++
	def self.combine(email, website, user_id)
		user = User.find_by_email(email)
		return ErrorEnum::USER_NOT_EXIST if user.nil?
		third_party_user = ThirdPartyUser.find_by_website_and_user_id(website, user_id)
		return ErrorEnum::THIRD_PARTY_USER_NOT_EXIST if third_party_user.nil?
		return third_party_user.bind(user)
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

	scope :normal_list, where(:color => COLOR_NORMAL, :status.gt => 0)
	scope :black_list, where(:color => COLOR_BLACK, :status.gt => -1)
	scope :white_list, where(:color => COLOR_WHITE, :status.gt => 1)
	scope :deleted_users, where(status: -1)

	def self.ids_not_in_blacklist
		return User.any_of({color: 0}, {color: 1})
	end

	def update_user(attributes)
		select_attrs = %w(status birthday gender address phone postcode company identity_card username true_name)
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
		return ErrorEnum::WRONG_USER_COLOR if ![-1, 0, 1].include?(role)
		self.color = color
		return self.save
	end

	def set_lock(lock)
		self.lock = lock == true
		return self.save
	end

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
end
