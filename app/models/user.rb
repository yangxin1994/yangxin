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
	field :role, :type => Integer, default: 0
	field :auth_key, :type => String
	field :last_visit_time, :type => Integer
	field :level, :type => Integer, default: 0
	field :level_expire_time, :type => Integer, default: -1
<<<<<<< HEAD

=======
>>>>>>> 14627a53cf3501e03f0fffcb8ff1cf9282ab2cd2
	field :birthday, :type => Integer, default: -1
	field :gender, :type => Boolean
	field :address, :type => String
	field :postcode, :type => String
	field :phone, :type => String

	#################################
	# QuillMe
	field :point, :type => Integer
<<<<<<< HEAD
	has_many :point_logs, :class_name => "PointLog", :foreign_key => "user_id"  
	has_many :orders, :class_name => "Order", :foreign_key => "user_id" 
	# QuillAdmin
	has_many :operate_orders, :class_name => "Order", :foreign_key => "operated_admin_id"
	has_many :operate_point_logs, :class_name => "PointLog", :foreign_key => "operated_admin_id"  
=======
	has_many :point_logs, :class_name => "PointLog", :foreign_key => "user_id"	
	has_many :orders, :class_name => "Order", :foreign_key => "user_id"	
	# QuillAdmin
	has_many :operate_orders, :class_name => "Order", :foreign_key => "operated_admin_id"
	has_many :operate_point_logs, :class_name => "PointLog", :foreign_key => "operated_admin_id"	
>>>>>>> 14627a53cf3501e03f0fffcb8ff1cf9282ab2cd2
	
	before_save :set_updated_at
	before_update :set_updated_at

	attr_accessible :email, :username, :password, :registered_at

	has_many :surveys
	has_many :groups
	has_many :materials
	has_many :public_notices
	has_many :question_feedbacks, class_name: "Feedback", inverse_of: :question_user
	has_many :answer_feedbacks, class_name: "Feedback", inverse_of: :answer_user
	has_many :faqs
	has_many :advertisements
<<<<<<< HEAD
=======

	has_many :answers


>>>>>>> 14627a53cf3501e03f0fffcb8ff1cf9282ab2cd2

	private
	def set_updated_at
		self.updated_at = Time.now.to_i
	end


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
		self.birthday = user_info["birthday"]
		self.gender = user_info["gender"]
		self.address = user_info["address"]
		self.postcode = user_info["postcode"]
		self.phone = user_info["phone"]
		return self.save
	end

	def init_attr_survey(answer)
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
		user.status = 1
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
	def reset_password(old_password, new_password)
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
############### operations about quality control questions #################
#++
	def create_quality_control_question(quality_control_type, question_type, question_number)
		return Question.new_quality_control_question(quality_control_type, question_type, question_number, self)
	end

	def update_quality_control_question(question_id, question_object)
		question = Question.find_by_id(question_id)
		return ErrorEnum::QUESTION_NOT_EXIST if question.nil?
		return question.update_quality_control_question(question_object, self)
	end

	def update_quality_control_answer(answer_object)
		QualityControlQuestionAnswer.update_answers(answer_object, self)
	end

	def list_quality_control_questions(quality_control_type)
		return Question.list_quality_control_questions(quality_control_type, self)
	end

	def show_quality_control_question(question_id)
		question = Question.find_by_id(question_id)
		return ErrorEnum::QUESTION_NOT_EXIST if question.nil?
		return question.show_quality_control_question(self)
	end

	def delete_quality_control_question(question_id)
		question = QualityControlQuestion.find_by_id(question_id)
		return ErrorEnum::QUESTION_NOT_EXIST if question.nil?
		return question.delete_quality_control_question(self)
	end
end
