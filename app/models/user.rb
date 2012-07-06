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

  field :birthday, :type => Integer, default: -1
  field :gender, :type => Boolean
  field :address, :type => String
  field :postcode, :type => String
  field :phone, :type => String

	has_many :surveys
	has_many :groups
	has_many :materials
  has_many :public_notices
  has_many :question_feedbacks, class_name: "Feedback", inverse_of: :question_user
  has_many :answer_feedbacks, class_name: "Feedback", inverse_of: :answer_user
  has_many :faqs

	attr_accessible :email, :username, :password, :registered_at

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

	def self.create_new_visitor_user(user)
		user = User.new
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
		return ErrorEnum::EMAIL_NOT_EXIST if user.nil?			# email account does not exist
		return true  if user.is_activate?
		return ErrorEnum::ACTIVATE_EXPIRED if Time.now.to_i - activate_info["time"].to_i > OOPSDATA[RailsEnv.get_rails_env]["activate_expiration_time"].to_i		# expired
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
		return ErrorEnum::EMAIL_NOT_EXIST if !user_exist_by_email?(email)			# email account does not exist
		return ErrorEnum::EMAIL_NOT_ACTIVATED if !user_activate?(email)		# not activated
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
		user = User.find_by_email_username(email_username)
		return ErrorEnum::USER_NOT_EXIST if user.nil?
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
		return ErrorEnum::EMAIL_NOT_EXIST if user_exist?(email) == false			# email account does not exist
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
		return ErrorEnum::WRONG_PASSWORD if self.password != Encryption.encrypt_password(old_password)	# wrong password
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
############### operations about survey #################
#++

	def tags
		
	end

	#*description*: delete a survey
	#
	#*params*:
	#* the id of the survey to be deleted
	#
	#*retval*:
	#* true: when successfully deleted
	#* false: unkown error
	#* SURVEY_NOT_EXIST
	#* UNAUTHORIZED
	def destroy_survey(survey_id)
		survey = Survey.find_by_id(survey_id)
		return ErrorEnum::SURVEY_NOT_EXIST if survey.nil?
		return survey.delete(self)
	end

	#*description*: recover a survey
	#
	#*params*:
	#* the id of the survey to be recovered
	#
	#*retval*:
	#* true: when successfully recovered
	#* false: unkown error
	#* SURVEY_NOT_EXIST
	#* UNAUTHORIZED
	def recover_survey(survey_id)
		survey = Survey.find_by_id_in_trash(survey_id)
		return ErrorEnum::SURVEY_NOT_EXIST if survey.nil?
		return survey.recover(self)
	end

	#*description*: thoroughly destroy a survey
	#
	#*params*:
	#* the id of the survey to be cleared
	#
	#*retval*:
	#* true: when successfully cleared
	#* false: unkown error
	#* SURVEY_NOT_EXIST
	#* UNAUTHORIZED
	def clear_survey(survey_id)
		survey = Survey.find_by_id_in_trash(survey_id)
		return ErrorEnum::SURVEY_NOT_EXIST if survey.nil?
		return survey.clear(self)
	end

	#*description*: clone a survey
	#
	#*params*:
	#* the id of the survey to be cloned
	#
	#*retval*:
	#* true: when successfully deleted
	#* false: unkown error
	#* SURVEY_NOT_EXIST
	#* UNAUTHORIZED
	def clone_survey(survey_id)
		survey = Survey.find_by_id(survey_id)
		return ErrorEnum::SURVEY_NOT_EXIST if survey.nil?
		return survey.clone(self)
	end

	#*description*: get a survey object
	#
	#*params*:
	#* the id of the survey object
	#
	#*retval*:
	#* the survey object if successfully obtained
	#* SURVEY_NOT_EXIST
	#* UNAUTHORIZED
	def get_survey_object(survey_id)
		return Survey.get_survey_object(self, survey_id)
	end

	#*description*: get survey object list given a list of tags
	#
	#*params*:
	#* tags
	#
	#*retval*:
	#* the survey object list
	def get_survey_object_list(tags)
		return Survey.get_object_list(self, tags)
	end

	#*description*: update tags of a survey
	#
	#*params*:
	#* the id of the survey object
	#* the tags to be added
	#
	#*retval*:
	#* the survey object if successfully updating tags
	#* SURVEY_NOT_EXIST
	#* UNAUTHORIZED
	def update_survey_tags(survey_id, tags)
		survey = Survey.find_by_id(survey_id)
		return ErrorEnum::SURVEY_NOT_EXIST if survey.nil?
		return survey.update_tags(self, tags)
	end

	#*description*: submit a survey to administrator for reviewing
	#
	#*params*:
	#* the id of the survey
	#* the message that the user wants to give the administrator
	#
	#*retval*:
	#* true
	#* SURVEY_NOT_EXIST
	#* UNAUTHORIZED
	#* WRONG_PUBLISH_STATUS
	def submit_survey(survey_id, message)
		survey = Survey.find_by_id(survey_id)
		return ErrorEnum::SURVEY_NOT_EXIST if survey.nil?
		return survey.submit(self, message)
	end

	#*description*: reject a survey
	#
	#*params*:
	#* the id of the survey
	#* the message that the user wants to give the administrator
	#
	#*retval*:
	#* true
	#* SURVEY_NOT_EXIST
	#* UNAUTHORIZED
	#* WRONG_PUBLISH_STATUS
	def reject_survey(survey_id, message)
		survey = Survey.find_by_id(survey_id)
		return ErrorEnum::SURVEY_NOT_EXIST if survey.nil?
		return survey.reject(self, message)
	end

	#*description*: publish a survey
	#
	#*params*:
	#* the id of the survey
	#* the message that the user wants to give the administrator
	#
	#*retval*:
	#* true
	#* SURVEY_NOT_EXIST
	#* UNAUTHORIZED
	#* WRONG_PUBLISH_STATUS
	def publish_survey(survey_id, message)
		survey = Survey.find_by_id(survey_id)
		return ErrorEnum::SURVEY_NOT_EXIST if survey.nil?
		return survey.publish(self, message)
	end

	#*description*: close a survey
	#
	#*params*:
	#* the id of the survey
	#* the message that the user wants to give the administrator
	#
	#*retval*:
	#* true
	#* SURVEY_NOT_EXIST
	#* UNAUTHORIZED
	def close_survey(survey_id, message)
		survey = Survey.find_by_id(survey_id)
		return ErrorEnum::SURVEY_NOT_EXIST if survey.nil?
		return survey.close(self, message)
	end

	#*description*: pause a survey
	#
	#*params*:
	#* the id of the survey
	#* the message that the user wants to give the administrator
	#
	#*retval*:
	#* true
	#* SURVEY_NOT_EXIST
	#* UNAUTHORIZED
	#* WRONG_PUBLISH_STATUS
	def pause_survey(survey_id, message)
		survey = Survey.find_by_id(survey_id)
		return ErrorEnum::SURVEY_NOT_EXIST if survey.nil?
		return survey.pause(self, message)
	end

	#*description*: createa a new question
	#
	#*params*:
	#* the id of the survey, in which the question is created
	#* index of the page, in which the question is created
	#* id of the question after which the new question is created
	#* type of new question
	#
	#*retval*:
	#* the question object if successfully obtained
	#* SURVEY_NOT_EXIST
	#* QUESTION_NOT_EXIST
	#* UNAUTHORIZED
	#* OVERFLOW
	def create_question(survey_id, page_index, question_id, question_type)
		survey = Survey.find_by_id(survey_id)
		return ErrorEnum::SURVEY_NOT_EXIST if survey.nil?
		return survey.create_question(self, page_index, question_id, question_type)
	end

	#*description*: update a question
	#
	#*params*:
	#* id of the survey, in which the updated question is
	#* id of the question to be updated
	#* question object
	#
	#*retval*:
	#* the question object after updated
	#* ErrorEnum ::SURVEY_NOT_EXIST
	#* ErrorEnum ::UNAUTHORIZED
	#* ErrorEnum ::QUESTION_NOT_EXIST
	#* ErrorEnum ::WRONG_DATA_TYPE
	def update_question(survey_id, question_id, question_obj)
		survey = Survey.find_by_id(survey_id)
		return ErrorEnum::SURVEY_NOT_EXIST if survey.nil?
		return survey.update_question(self, question_id, question_obj)
	end

	#*description*: move a question
	#
	#*params*:
	#* id of the survey, in which the question is
	#* id of the question to be moved
	#* index of page where the moved question is inserted
	#* id of the question after which the moved question is inserted
	#
	#*retval*:
	#* true if successfuly moved
	#* false
	#* ErrorEnum ::SURVEY_NOT_EXIST
	#* ErrorEnum ::UNAUTHORIZED
	#* ErrorEnum ::QUESTION_NOT_EXIST
	#* ErrorEnum ::OVERFLOW
	def move_question(survey_id, question_id_1, page_index, question_id_2)
		survey = Survey.find_by_id(survey_id)
		return ErrorEnum::SURVEY_NOT_EXIST if survey.nil?
		return survey.move_question(self, question_id_1, page_index, question_id_2)
	end

	#*description*: clone a question
	#
	#*params*:
	#* id of the survey, in which the question is
	#* id of the question to be cloned
	#* index of page where the cloned question is inserted
	#* id of the question after which the cloned question is inserted
	#
	#*retval*:
	#* the new question object if successfully cloned
	#* ErrorEnum ::SURVEY_NOT_EXIST
	#* ErrorEnum ::UNAUTHORIZED
	#* ErrorEnum ::QUESTION_NOT_EXIST
	#* ErrorEnum ::OVERFLOW
	def clone_question(survey_id, question_id_1, page_index, question_id_2)
		survey = Survey.find_by_id(survey_id)
		return ErrorEnum::SURVEY_NOT_EXIST if survey.nil?
		return survey.clone_question(self, question_id_1, page_index, question_id_2)
	end

	#*description*: get a question object
	#
	#*params*:
	#* id of the survey, in which the question is
	#* id of the question to be required
	#
	#*retval*:
	#* the question object if successfully obtained
	#* ErrorEnum ::SURVEY_NOT_EXIST
	#* ErrorEnum ::UNAUTHORIZED
	#* ErrorEnum ::QUESTION_NOT_EXIST 
	def get_question_object(survey_id, question_id)
		survey = Survey.find_by_id(survey_id)
		return ErrorEnum::SURVEY_NOT_EXIST if survey.nil?
		survey.get_question_object(self, question_id)
	end

	#*description*: delete a question
	#
	#*params*:
	#* id of the survey, in which the question is
	#* id of the question to be deleted
	#
	#*retval*:
	#* true if successfully deleted
	#* false
	#* ErrorEnum ::SURVEY_NOT_EXIST
	#* ErrorEnum ::UNAUTHORIZED
	#* ErrorEnum ::QUESTION_NOT_EXIST 
	def delete_question(survey_id, question_id)
		survey = Survey.find_by_id(survey_id)
		return ErrorEnum::SURVEY_NOT_EXIST if survey.nil?
		return survey.delete_question(self, question_id)
	end

	#*description*: create a page
	#
	#*params*:
	#* id of the survey, in which the new page is created
	#* index of the page, after which the new page is inserted
	#
	#*retval*:
	#* true if successfully created
	#* false
	#* ErrorEnum ::SURVEY_NOT_EXIST
	#* ErrorEnum ::UNAUTHORIZED
	#* ErrorEnum ::OVERFLOW 
	def create_page(survey_id, page_index)
		survey = Survey.find_by_id(survey_id)
		return ErrorEnum::SURVEY_NOT_EXIST if survey.nil?
		return survey.create_page(self, page_index)
	end

	#*description*: show a page
	#
	#*params*:
	#* id of the survey, in which the page is
	#* index of the page to be shown
	#
	#*retval*:
	#* the page object if successfully obtained
	#* ErrorEnum ::SURVEY_NOT_EXIST
	#* ErrorEnum ::UNAUTHORIZED 
	#* ErrorEnum ::OVERFLOW 
	def show_page(survey_id, page_index)
		survey = Survey.find_by_id(survey_id)
		return ErrorEnum::SURVEY_NOT_EXIST if survey.nil?
		return survey.show_page(self, page_index)
	end

	#*description*: clone a page
	#
	#*params*:
	#* id of the survey, in which the page is
	#* index of the page to be cloned
	#* index of the page, after which the new page is inserted
	#
	#*retval*:
	#* the object of the cloned page if successfully cloned
	#* ErrorEnum ::SURVEY_NOT_EXIST
	#* ErrorEnum ::UNAUTHORIZED 
	#* ErrorEnum ::OVERFLOW 
	#* ErrorEnum ::QUESTION_NOT_EXIST 
	def clone_page(survey_id, page_index_1, page_index_2)
		survey = Survey.find_by_id(survey_id)
		return ErrorEnum::SURVEY_NOT_EXIST if survey.nil?
		return survey.clone_page(self, page_index_1, page_index_2)
	end

	#*description*: delete a page
	#
	#*params*:
	#* id of the survey, in which the page is
	#* index of the page to be deleted
	#
	#*retval*:
	#* true if the page is deleted
	#* false
	#* ErrorEnum ::SURVEY_NOT_EXIST
	#* ErrorEnum ::UNAUTHORIZED
	#* ErrorEnum ::OVERFLOW
	def delete_page(survey_id, page_index)
		survey = Survey.find_by_id(survey_id)
		return ErrorEnum::SURVEY_NOT_EXIST if survey.nil?
		return survey.delete_page(self, page_index)
	end

	#*description*: combine pages
	#
	#*params*:
	#* id of the survey, in which the pages are
	#* index of the page, from which the pages are combined
	#* index of the page, to which the pages are combined
	#
	#*retval*:
	#* true if the page is deleted
	#* false
	#* ErrorEnum ::SURVEY_NOT_EXIST
	#* ErrorEnum ::UNAUTHORIZED
	#* ErrorEnum ::OVERFLOW
	def combine_pages(survey_id, page_index_1, page_index_2)
		survey = Survey.find_by_id(survey_id)
		return ErrorEnum::SURVEY_NOT_EXIST if survey.nil?
		return survey.combine_pages(self, page_index_1, page_index_2)
	end

	#*description*: move page
	#
	#*params*:
	#* id of the survey, in which the pages are
	#* index of the page to be moved
	#* index of the page, after which the moved page is inserted to
	#
	#*retval*:
	#* true if the page is moved
	#* false
	#* ErrorEnum ::SURVEY_NOT_EXIST
	#* ErrorEnum ::UNAUTHORIZED
	#* ErrorEnum ::OVERFLOW
	def move_page(survey_id, page_index_1, page_index_2)
		survey = Survey.find_by_id(survey_id)
		return ErrorEnum::SURVEY_NOT_EXIST if survey.nil?
		survey.move_page(self, page_index_1, page_index_2)
	end

#--
############### operations about quotas #################
#++
	def show_quota(survey_id)
		survey = Survey.find_by_id(survey_id)
		return ErrorEnum::SURVEY_NOT_EXIST if survey.nil?
		survey.show_quota(self)
	end

	def add_quota_rule(survey_id, quota_rule)
		survey = Survey.find_by_id(survey_id)
		return ErrorEnum::SURVEY_NOT_EXIST if survey.nil?
		survey.add_quota_rule(self, quota_rule)
	end

	def update_quota_rule(survey_id, quota_rule_index, quota_rule)
		survey = Survey.find_by_id(survey_id)
		return ErrorEnum::SURVEY_NOT_EXIST if survey.nil?
		survey.update_quota_rule(self, quota_rule_index, quota_rule)
	end

	def delete_quota_rule(survey_id, quota_rule_index)
		survey = Survey.find_by_id(survey_id)
		return ErrorEnum::SURVEY_NOT_EXIST if survey.nil?
		survey.delete_quota_rule(self, quota_rule_index)
	end

	def set_exclusive(survey_id, is_exclusive)
		survey = Survey.find_by_id(survey_id)
		return ErrorEnum::SURVEY_NOT_EXIST if survey.nil?
		survey.set_exclusive(self, is_exclusive)
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
		return third_party_user.bind(self)
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
