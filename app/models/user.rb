require 'encryption'
require 'error_enum'
require 'tool'
#Corresponding to the User collection in database. Record the user information and activities related to the usage of OopsData system.
class User
  include Mongoid::Document
  field :email, :type => String
  field :username, :type => String
  field :password, :type => String
# 0 registered but not activated
# 1 registered and activated
  field :status, :type => Integer, default: 0
  field :last_login_time, :type => Integer
  field :last_login_ip, :type => String
  field :login_count, :type => Integer, default: 0
  field :created_at, :type => Integer, default: -> { Time.now.to_i }
  field :updated_at, :type => Integer
  field :activate_time, :type => Integer
  field :introducer_id, :type => Integer
  field :introducer_to_pay, :type => Float
# 0 user
# 1 administrator
  field :role, :type => Integer, default: 0
  field :auth_key, :type => String

	before_save :set_updated_at
	before_update :set_updated_at

	attr_accessible :email, :username, :password

	private
	def set_updated_at
		self.updated_at = Time.now.to_i
	end

	public
	#*description*: find a user given an email
	#
	#*params*:
	#* email of the user
	#
	#*retval*:
	#* the user instance: when the user exists
	#* nil: when the user does not exist
	def self.find_by_email(email)
		return User.where(:email => email)[0]
	end
	
	#*description*: check whether an email has been registered as an user
	#
	#*params*:
	#* email of the user
	#
	#*retval*:
	#* true or false
	def self.user_exist?(email)
		return exists?(conditions: { email: email })
	end

	#*description*: check whether an user has activated
	#
	#*params*:
	#* email of the user
	#
	#*retval*:
	#* true or false
	def self.user_activate?(email)
		user = User.find_by_email(email)
		return !!(user && user.status == 1)
	end

	#*description*: create a new user
	#
	#*params*:
	#* a user hash
	#
	#*retval*:
	#* the new user instance: when successfully created
	def self.check_and_create_new(user)
		# check whether the email acount is illegal
		return ErrorEnum::ILLEGAL_EMAIL if Tool.email_illegal?(user["email"])
		# check whether this user already exists
		if user_exist?(user["email"])
			return ErrorEnum::EMAIL_ACTIVATED if user_activate?(user["email"])
			return ErrorEnum::EMAIL_NOT_ACTIVATED if !user_activate?(user["email"])
		end
		return ErrorEnum::WRONG_PASSWORD_CONFIRMATION if user["password"] != user["password_confirmation"]	# wrong password confirmation

#		user_hash = user.merge("password" => Encryption.encrypt_password(user["password"])).delete("password_confirmation")
		user = User.new(user.merge("password" => Encryption.encrypt_password(user["password"])))
#		user = User.new(user_hash)
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
		return ErrorEnum::EMAIL_NOT_EXIST if !user_exist?(activate_info["email"])			# email account does not exist
		return true  if user_activate?(activate_info["email"])					# already activated
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
	def self.thrid_party_login(email, client_ip)
		return ErrorEnum::EMAIL_NOT_EXIST if !user_exist?(email)			# email account does not exist
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
	def self.login(email, password, client_ip)
		return ErrorEnum::EMAIL_NOT_EXIST if !user_exist?(email)			# email account does not exist
		return ErrorEnum::EMAIL_NOT_ACTIVATED if !user_activate?(email)		# not activated
		user = User.find_by_email(email)
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
	def self.set_auth_key(email, auth_key)
		user = User.find_by_email(email)
		user.auth_key = auth_key
		user.save
		return true
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
############### operations about user information #################
#++
	#*description*: update an user's information
	#
	#*params*:
	#* the user information hash
	#
	#*retval*:
	def update_information(profile)
		UserInformation.update(profile)
	end

	#*description*: obtain the groups of this user
	#
	#*params*:
	#
	#*retval*:
	#* an array of group objects of this user
	def groups
		return Group.get_groups(self.email)
	end

#--
############### operations about group #################
#++
	#*description*: create a new group for this user
	#
	#*params*:
	#* name of the new group
	#* description of the new group
	#* array of members of the new group
	#
	#*retval*:
	#* the group object: when successfully created
	#* ErrorEnum ::EMAIL_NOT_EXIST
	def create_group(name, description, members)
		return Group.check_and_create_new(self.email, name, description, members)
	end

	#*description*: update a group for this user
	#
	#*params*:
	#* group object to be updated
	#
	#*retval*:
	#* the group object: when successfully updated
	#* ErrorEnum ::GROUP_NOT_EXIST
	def update_group(group_id, group_obj)
		return Group.update(self.email, group_id, group_obj)
	end

	#*description*: delete a group for this user
	#
	#*params*:
	#* name of the group
	#
	#*retval*:
	#* true: when successfully deleted
	#* NOT_EXIST
	def destroy_group(name)
		return Group.delete(self.email, name)
	end

	#*description*: get a group for this user
	#
	#*params*:
	#* name of the group
	#
	#*retval*:
	#* the group instance: when successfully updated
	#* NOT_EXIST
	def show_group(name)
		return Group.show(self.email, name)
	end

#--
############### operations about survey #################
#++
	#*description*: get surveys for this user
	#
	#*params*:
	#
	#*retval*:
	#* the array of surveys: when successfully obtained
	#* NOT_EXIST
	def surveys(tags)
		return Survey.surveys_of(self.email)
	end

	#*description*: save meta data for a survey
	#
	#*params*:
	#* the survey object, the meta data of which is to be saved
	#
	#*retval*:
	#* true: when successfully saved
	#* false: unkown error
	#* NOT_EXIST
	#* UNAUTHORIZED
	def save_meta_data(survey_object)
		return Survey.save_meta_data(self.email, survey_object)
	end
	
	#*description*: delete a survey
	#
	#*params*:
	#* the id of the survey to be deleted
	#
	#*retval*:
	#* true: when successfully deleted
	#* false: unkown error
	#* NOT_EXIST
	#* UNAUTHORIZED
	def destroy_survey(survey_id)
		survey = Survey.find_by_id(survey_id)
		return ErrorEnum::SURVEY_NOT_EXIST if survey == nil
		return survey.delete(self.email)
	end

	#*description*: clone a survey
	#
	#*params*:
	#* the id of the survey to be cloned
	#
	#*retval*:
	#* true: when successfully deleted
	#* false: unkown error
	#* NOT_EXIST
	#* UNAUTHORIZED
	def clone_survey(survey_id)
		survey = Survey.find_by_id(survey_id)
		return ErrorEnum::SURVEY_NOT_EXIST if survey == nil
		return survey.clone(self.email)
	end

	#*description*: get a survey object
	#
	#*params*:
	#* the id of the survey object
	#
	#*retval*:
	#* the survey object if successfully obtained
	#* NOT_EXIST
	#* UNAUTHORIZED
	def get_survey_object(survey_id)
		return Survey.get_survey_object(self.email, survey_id)
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
		return ErrorEnum::SURVEY_NOT_EXIST if survey == nil
		return survey.create_question(self.email, page_index, question_id, question_type)
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
		return ErrorEnum::SURVEY_NOT_EXIST if survey == nil
		return survey.update_question(self.email, question_id, question_obj)
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
		return ErrorEnum::SURVEY_NOT_EXIST if survey == nil
		return survey.move_question(self.email, question_id_1, page_index, question_id_2)
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
		return ErrorEnum::SURVEY_NOT_EXIST if survey == nil
		return survey.clone_question(self.email, question_id_1, page_index, question_id_2)
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
		return ErrorEnum::SURVEY_NOT_EXIST if survey == nil
		survey.get_question_object(self.email, question_id)
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
		return ErrorEnum::SURVEY_NOT_EXIST if survey == nil
		return survey.delete_question(self.email, question_id)
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
		return ErrorEnum::SURVEY_NOT_EXIST if survey == nil
		return survey.create_page(self.email, page_index)
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
		return ErrorEnum::SURVEY_NOT_EXIST if survey == nil
		return survey.show_page(self.email, page_index)
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
		return ErrorEnum::SURVEY_NOT_EXIST if survey == nil
		return survey.clone_page(self.email, page_index_1, page_index_2)
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
		return ErrorEnum::SURVEY_NOT_EXIST if survey == nil
		return survey.delete_page(self.email, page_index)
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
		return ErrorEnum::SURVEY_NOT_EXIST if survey == nil
		return survey.combine_pages(self.email, page_index_1, page_index_2)
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
		return ErrorEnum::SURVEY_NOT_EXIST if survey == nil
		survey.move_page(self.email, page_index_1, page_index_2)
	end

#--
############### operations about charge #################
#++
	#Obtain the charges of this user
	def charges
		Charge.charges_of(self.email)
	end

#--
############### operations about resource #################
#++
	# create a new resource
	def create_resource(resource, resource_type, location, title)
		return Resource.check_and_create_new(self.email, resource_type, location, title)
	end

	# get a list of resources
	def get_resource_object_list(resource_type)
		resource_list = Resource.get_object_list(self.email, resource_type)
		return resource_list
	end

	# get a resource object
	def get_resource_object(resource_id)
		resource = Resource.get_object(self.email, resource_id)
		return resource
	end

	# destroy a resource
	def destroy_resource(resource_id)
		resource = Resource.find_by_id(resource_id)
		return ErrorEnum::RESOURCE_NOT_EXIST if resource.nil?
		retval = resource.delete(self.email)
		return retval
	end

	# clear a resource
	def clear_resource(resource_id)
		resource = Resource.find_by_id(resource_id)
		return ErrorEnum::RESOURCE_NOT_EXIST if resource.nil?
		retval = resource.clear(self.email)
		return retval
	end

	# update title of the resource
	def update_resource_title(resource)
		resource = Resource.find_by_id(resource.resource_id)
		return ErrorEnum::RESOURCE_NOT_EXIST if resource.nil?
		retval = resource.update_title(self.email, resource.title)
		return retval
	end

#--
############### operations about third party user #################
#++
	def self.combine(email, website, user_id)
		user = User.find_by_email(email)
		return ErrorEnum::EMAIL_NOT_EXIST if user.nil?
		third_party_user = ThirdPartyUser.find_by_website_and_user_id(website, user_id)
		return ErrorEnum::THIRD_PARTY_USER_NOT_EXIST if third_party_user.nil?
		third_party_user.email = email
		return third_party_user.save
	end
end
