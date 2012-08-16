# encoding: utf-8
require 'encryption'
require 'error_enum'
require 'tool'
#Corresponding to the User collection in database. Record the user information and activities related to the usage of OopsData system.
class User
	include Mongoid::Document
	include Mongoid::Timestamps
	field :email, :type => String
	field :username, :type => String
	field :password, :type => String
# 0 unregistered
# 1 registered but not activated
# 2 registered, activated, but not signed in
# 3, 4, ... 用户首次登录后，需要填写一些个人信息，状态可以记录用户填写个人信息到了哪一步，以便用户填写过程中关闭浏览器，再次打开后可以继续填写
# -1 deleted
	field :status, :type => Integer, default: 0
	field :last_login_time, :type => Integer
	field :last_login_ip, :type => String
	field :login_count, :type => Integer, default: 0
	field :activate_time, :type => Integer
	field :introducer_id, :type => Integer
	field :introducer_to_pay, :type => Float
# 0 user
# 1 administrator
# 2 belongs to: White List
# 4 belongs to: Black List

	field :role, :type => Integer, default: 0
	field :auth_key, :type => String
	field :last_visit_time, :type => Integer
	field :level, :type => Integer, default: 0
	field :level_expire_time, :type => Integer, default: -1

	field :birthday, :type => Integer, default: -1
	field :gender, :type => Boolean
	field :address, :type => Array
	field :postcode, :type => String
	field :phone, :type => String


	has_and_belongs_to_many :messages, inverse_of: nil
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


	has_many :answers



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
		return User.where(:email => email, :status.gt => -1)[0]
	end

	def self.find_by_username(username)
		return User.where(:username => username, :status.gt => -1)[0]
	end

	def self.find_by_id(user_id)
		return User.where(:_id => user_id, :status.gt => -1)[0]
	end

	def update_last_visit_time
		self.last_visit_time = Time.now.to_i
		self.save
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
		return self.save
	end

	def init_attr_survey(survey_id, answer_content)
		retval Answer.create_user_attr_survey_answer(self, survey_id, answer_content)
		return retval
	end

	def skip_init_step
		self.status = self.status + 1 if self.status <= 4
		return self.save
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

	#*description*: check whether an user is adminstrator
	#
	#*params*:
	#
	#*retval*:
	#* true or false
	def is_admin
		return self.role == 1
	end

	def is_survey_auditor
		return self.class == SurveyAuditor
	end

	def is_answer_auditor
		return self.class == AnswerAuditor
	end

	def is_entry_clerk
		return self.class == EntryClerk
	end

	def is_interviewer
		return self.class == Interviewer
	end

	#*description*: create a new user
	#
	#*params*:
	#* a user hash
	#
	#*retval*:
	#* the new user instance: when successfully created
	def self.create_new_registered_user(user, current_user)
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
		user.save
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

	#*description*: user login with third party account
	#
	#*params*:
	#* email address of the user
	#* ip address of the user
	#
	#*retval*:
	#* true: when successfully login
	#* EMAIL_NOT_EXIST
	#* EMAIL_NOT_ACTIVATED
	def self.third_party_login(email, client_ip)
		return ErrorEnum::USER_NOT_EXIST if !user_exist_by_email?(email)      # email account does not exist
		return ErrorEnum::EMAIL_NOT_ACTIVATED if !user_activate?(email)   # not activated
		user = User.find_by_email(email)
		# record the login information
		user.last_login_time = Time.now.to_i
		user.last_login_ip = client_ip
		user.login_count = user.login_count + 1
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
	def self.login(email_username, password, client_ip)
		user = User.find_by_email(email_username)
		return ErrorEnum::USER_NOT_EXIST if user.nil?
		# There is no is_activated
		return ErrorEnum::USER_NOT_ACTIVATED if !user.is_activated
		return ErrorEnum::WRONG_PASSWORD if user.password != Encryption.encrypt_password(password)
		# record the login information
		user.last_login_time = Time.now.to_i
		user.last_login_ip = client_ip
		user.login_count = user.login_count + 1
		return user.save
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
		return true
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
	def create_message_for_all(title, content)
		sended_messages.create(:title => title, :content => content, :sender_id => id)
	end

	def create_message(title, content, receiver = [])
		m = sended_messages.create(:title => title, :content => content, :type => 1)
		return m unless m.is_a? Message
		receiver.each do |r|
			u = User.find_by_id(r)
			u.messages << m# => unless m.created_at.nil? 
			u.save
		end
		m
	end

	def show_messages
		Message.unread(created_at).select{ |m| (message_ids.include? m.id) or (m.type == 0)}
	end

#--
############### operations about point #################
#++
# admin inc
	def operate_point(operated_point, user_id)
		u = User.find(user_id)
		return false unless u.is_a? User
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

	ROLE_NORMAL = 0
	ROLE_WHITE = 2
	ROLE_BLACK = 4

	#--
	# instance methods
	#++

	#--
	# class methods
	#++

	scope :black_list, where(role: ROLE_BLACK)
	scope :white_list, where(role: ROLE_WHITE)

	def self.update_user(user_id, attributes)
		user = User.find_by_id(user_id)
		return ErrorEnum::USER_NOT_EXIST if user.nil?

		select_attrs = %w(birthday gender address phone postcode status)
		attributes.select!{|k,v| select_attrs.include?(k.to_s)}

		updated_user = User.collection.find_and_modify(:query => {_id: user.id}, :update => attributes, new: true)

		return User.where(_id: updated_user["_id"]).first
	end

	def self.change_white_user(user_id)
		user = User.find_by_id(user_id.to_s.strip)	
		return ErrorEnum::USER_NOT_EXIST if user.nil?

		if user.role != ROLE_WHITE then
			user.role = ROLE_WHITE
		elsif user.role != ROLE_NORMAL
			user.role = ROLE_NORMAL
		end

		if user.save then
			if user.role == ROLE_WHITE then 
				user[:white] = true 
			else
				user[:white] = false 
			end

			return user 
		else
			return ErrorEnum::USER_SAVE_FAILED
		end
	end

	def self.change_black_user(user_id)
		user = User.find_by_id(user_id.to_s.strip)	
		return ErrorEnum::USER_NOT_EXIST if user.nil?

		if user.role != ROLE_BLACK then
			user.role = ROLE_BLACK
		elsif user.role != ROLE_NORMAL
			user.role = ROLE_NORMAL
		end

		if user.save then
			if user.role == ROLE_BLACK then 
				user[:black] = true 
			else
				user[:black] = false
			end

			return user 
		else
			return ErrorEnum::USER_SAVE_FAILED
		end
	end

	def self.change_to_system_password(user_id)
		user = User.find_by_id(user_id)
		return ErrorEnum::USER_NOT_EXIST if user.nil?

		# generate rand number
		sys_pwd = 1
		while sys_pwd < 16**7 do
			sys_pwd = rand(16**8-1)
		end
		sys_pwd = sys_pwd.to_s(16)

		user.password = Encryption.encrypt_password(sys_pwd)
		if !user.save then 
			return ErrorEnum::USER_SAVE_FAILED
		end

		# maybe, should be send the pwd to his register email
		#
		# CODE:
		#
		# if user.email.to_s.strip !="" then
		# 	mail = OopsMail::OMail.new("Change password to new system password.", "Your new password:<b>#{sys_pwd}</b>")
		# 	sender = OopsMail::EmailSender.new("customer", "customer@netranking.cn", "netrankingcust")
		# 	receiver = OopsMail::EmailReceiver.new(user.username || user.email.split("@")[0], user.email)
		# 	email = OopsMail::Email.new(sender, receiver, mail)
		# 	OopsMail.send_email(email)
		# end
		#

		return user 
	end

	#--
	# **************************************************
	#++
end
