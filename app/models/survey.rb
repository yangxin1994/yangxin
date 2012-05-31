# encoding: utf-8
require 'error_enum'
require 'securerandom'
#The survey object has the following structure
# {
#	 "owner_meail" : email of the owner user(string),
#	 "survey_id" : id of the survey(string),
#	 "title" : title of the survey(string),
#	 "subtitle" : subtitle of the survey(string),
#	 "welcome" : welcome of the survey(string),
#	 "closing" : closing of the survey(string),
#	 "header" : header of the survey(string),
#	 "footer" : footer of the survey(string),
#	 "description" : description of the survey(string),
#	 "created_at" : create time of the survey(integer),
#	 "constrains": an array of constrains
#	 "pages" : 2D array, each nested array is a page and each element is a Question id(2D array)
#	}
#Structure of question object can be found at Question
class Survey
	include Mongoid::Document
	field :owner_email, :type => String
	field :title, :type => String
	field :subtitle, :type => String
	field :welcome, :type => String
	field :closing, :type => String
	field :header, :type => String
	field :footer, :type => String
	field :description, :type => String
	field :created_at, :type => Integer, default: -> {Time.now.to_i}
	field :updated_at, :type => Integer
	field :status, :type => Integer, default: 0
	field :pages, :type => Array, default: Array.new
	field :constrains, :type => Array, default: Array.new
	field :tags, :type => Array, default: Array.new
	scope :surveys_of, lambda { |owner_email| where(:owner_email => owner_email, :status => 0) }
	scope :all_surveys_of, lambda { |owner_email| where(:owner_email => owner_email) }
	scope :trash_surveys_of, lambda { |owner_email| where(:owner_email => owner_email, :status => -1) }

	before_save :set_updated_at, :clear_survey_object
	before_update :set_updated_at, :clear_survey_object
	before_destroy :clear_survey_object

	META_ATTR_NAME_ARY = %w[title subtitle welcome closing header footer description]

	private
	def set_updated_at
		self.updated_at = Time.now.to_i
	end

	public

	#*description*: serialize current instance into a survey object
	#
	#*params*
	#
	#*retval*:
	#* a survey object
	def serialize
		survey_obj = Hash.new
		survey_obj["owner_email"] = self.owner_email
		survey_obj["survey_id"] = self._id.to_s
		survey_obj["created_at"] = self.created_at
		survey_obj["pages"] = Marshal.load(Marshal.dump(self.pages))
		survey_obj["tags"] = Marshal.load(Marshal.dump(self.tags))
		survey_obj["tags"] << "已删除" if self.status == -1 && !survey_obj["tags"].include?("已删除")
		META_ATTR_NAME_ARY.each do |attr_name|
			method_obj = self.method("#{attr_name}".to_sym)
			survey_obj[attr_name] = method_obj.call()
		end
		return survey_obj
	end

	#*description*: set default meta data, usually used for a newly created survey instance
	#
	#*params*
	#* email address of the owner
	#
	#*retval*:
	#* a survey object
	#* ErrorEnum ::EMAIL_NOT_EXIST
	def set_default_meta_data(owner_email)
		return ErrorEnum::EMAIL_NOT_EXIST if User.find_by_email(owner_email) == nil
		META_ATTR_NAME_ARY.each do |attr_name|
			method_obj = self.method("#{attr_name}=".to_sym)
			method_obj.call(OOPSDATA["survey_default_settings"][attr_name])
		end
		self._id = ""
		self.owner_email = owner_email
		return self.serialize
	end

	#*description*: find a survey by its id. return nil if cannot find
	#
	#*params*:
	#* id of the survey to be found
	#
	#*retval*:
	#* the survey instance found, or nil if cannot find
	def self.find_by_id(survey_id)
		return Survey.where(:_id => survey_id, :status.gt => -1)[0]
	end

	#*description*: find a survey by its id, trash included. return nil if cannot find
	#
	#*params*:
	#* id of the survey to be found
	#
	#*retval*:
	#* the survey instance found, or nil if cannot find
	def self.find_by_id_include_trash(survey_id)
		return Survey.where(:_id => survey_id)[0]
	end

	#*description*: find a survey by its id in trash. return nil if cannot find
	#
	#*params*:
	#* id of the survey to be found
	#
	#*retval*:
	#* the survey instance found, or nil if cannot find
	def self.find_by_id_in_trash(survey_id)
		return Survey.where(:_id => survey_id, :status => -1)[0]
	end

	#*description*: save meta data for a survey, meta data attributes are defined in META_ATTR_NAME_ARY
	#
	#*params*:
	#* email of the user doing this operation
	#* survey object, in which the attributes are
	#
	#*retval*:
	#* the survey object
	#* ErrorEnum ::SURVEY_NOT_EXIST : if cannot find the survey
	#* ErrorEnum ::UNAUTHORIZED : if the user is unauthorized to do that
	def self.save_meta_data(current_user_email, survey_obj)
		return ErrorEnum::UNAUTHORIZED if survey_obj["owner_email"]!= current_user_email
		if survey_obj["survey_id"] == ""
			# this is a new survey that has not been saved in database
			survey = Survey.new
			survey.owner_email = current_user_email
		else
			# this is an existing survey
			survey = Survey.find_by_id(survey_obj["survey_id"])
			return ErrorEnum::SURVEY_NOT_EXIST if survey == nil
			return ErrorEnum::UNAUTHORIZED if survey.owner_email != current_user_email
		end
		META_ATTR_NAME_ARY.each do |attr_name|
			method_obj = survey.method("#{attr_name}=".to_sym)
			method_obj.call(survey_obj[attr_name])
		end
		survey.save
		return survey.serialize
	end

	#*description*: remove current survey
	#
	#*params*:
	#* email of the user doing this operation
	#
	#*retval*:
	#* true: if successfully removed
	#* false
	#* ErrorEnum ::SURVEY_NOT_EXIST : if cannot find the survey
	#* ErrorEnum ::UNAUTHORIZED : if the user is unauthorized to do that
	def delete(current_user_email)
		return ErrorEnum::UNAUTHORIZED if self.owner_email != current_user_email
		return self.update_attributes(:status => -1)
	end

	#*description*: recover current survey
	#
	#*params*:
	#* email of the user doing this operation
	#
	#*retval*:
	#* true: if successfully recovered
	#* false
	#* ErrorEnum ::SURVEY_NOT_EXIST : if cannot find the survey in trash
	#* ErrorEnum ::UNAUTHORIZED : if the user is unauthorized to do that
	def recover(current_user_email)
		return ErrorEnum::UNAUTHORIZED if self.owner_email != current_user_email
		return ErrorEnum::SURVEY_NOT_EXIST if self.status != -1
		self.tags.delete("已删除")
		return self.update_attributes(:status => 0)
	end

	#*description*: clear current survey
	#
	#*params*:
	#* email of the user doing this operation
	#
	#*retval*:
	#* true: if successfully cleared
	#* false
	#* ErrorEnum ::SURVEY_NOT_EXIST : if cannot find the survey in trash
	#* ErrorEnum ::UNAUTHORIZED : if the user is unauthorized to do that
	def clear(current_user_email)
		return ErrorEnum::UNAUTHORIZED if self.owner_email != current_user_email
		return ErrorEnum::SURVEY_NOT_EXIST if self.status != -1
		return self.destroy
	end

	#*description*: clone the current survey instance
	#
	#*params*:
	#* email of the user doing this operation
	#
	#*retval*:
	#* the new survey instance: if successfully cloned
	#* ErrorEnum ::UNAUTHORIZED : if the user is unauthorized to do that
	def clone(current_user_email)
		return ErrorEnum::UNAUTHORIZED if self.owner_email != current_user_email

		# clone the meta data of the survey
		new_instance = super

		# clone all questions
		new_instance.pages.each do |page|
			page.each_with_index do |question_id, question_index|
				question = Question.find_by_id(question_id)
				return ErrorEnum::QUESTION_NOT_EXIST if question == nil
				cloned_question = question.clone
				page[question_index] = cloned_question._id.to_s
			end
		end
		
		# the constrains should also be cloned
		###################################################
		###################################################
		###################################################
		###################################################
		###################################################
		###################################################
	end
		
	#*description*: get a survey object. Will first try to get it from cache. If failed, will get it from database and write cache
	#
	#*params*:
	#* email of the user doing this operation
	#* id of the survey required
	#
	#*retval*:
	#* the survey object: if successfully obtained
	#* ErrorEnum ::SURVEY_NOT_EXIST : if cannot find the survey
	#* ErrorEnum ::UNAUTHORIZED : if the user is unauthorized to do that
	def self.get_survey_object(current_user_email, survey_id)
		survey_object = Cache.read(survey_id)
		if survey_object == nil
			survey = Survey.find_by_id_include_trash(survey_id)
			return ErrorEnum::SURVEY_NOT_EXIST if survey == nil
			survey_object = survey.serialize
			Cache.write(survey_id, survey_object)
		end
		return ErrorEnum::UNAUTHORIZED if survey_object["owner_email"] != current_user_email
		return survey_object
	end

	#*description*: update tags of this survey
	#
	#*params*:
	#* email of the user doing this operation
	#* tags to be updated
	#
	#*retval*:
	#* the survey object: if successfully cleared
	#* ErrorEnum ::UNAUTHORIZED : if the user is unauthorized to do that
	def update_tags(current_user_email, tags)
		return ErrorEnum::UNAUTHORIZED if self.owner_email != current_user_email
		tags.each do |tag|
			self.tags << tag.to_s
		end
		self.save
		return Survey.get_survey_object(current_user_email, self._id)
	end

	#*description*: add a tag to the survey
	#
	#*params*:
	#* email of the user doing this operation
	#* tag to be added
	#
	#*retval*:
	#* the survey object: if successfully cleared
	#* ErrorEnum ::UNAUTHORIZED : if the user is unauthorized to do that
	def add_tag(current_user_email, tag)
		return ErrorEnum::UNAUTHORIZED if self.owner_email != current_user_email
		return ErrorEnum::TAG_EXIST if self.tags.include?(tag)
		self.tags << tag.to_s
		self.save
		return Survey.get_survey_object(current_user_email, self._id)
	end

	#*description*: remove a tag from the survey
	#
	#*params*:
	#* email of the user doing this operation
	#* tag to be removed
	#
	#*retval*:
	#* the survey object: if successfully cleared
	#* ErrorEnum ::UNAUTHORIZED : if the user is unauthorized to do that
	def remove_tag(current_user_email, tag)
		return ErrorEnum::UNAUTHORIZED if self.owner_email != current_user_email
		return ErrorEnum::TAG_NOT_EXIST if !self.tags.include?(tag)
		self.tags.delete(tag)
		self.save
		return Survey.get_survey_object(current_user_email, self._id)
	end

	#*description*: obtain a list of Survey objects given a list of tags
	#
	#*params*:
	#* email of the user doing this operation
	#* tags
	#
	#*retval*:
	#* the survey object: if successfully cleared
	#* ErrorEnum ::UNAUTHORIZED : if the user is unauthorized to do that
	def self.get_object_list(current_user_email, tags)
		if tags.include?("已删除")
			surveys = Survey.trash_surveys_of(current_user_email)
			tags.delete("已删除")
		else
			surveys = Survey.surveys_of(current_user_email)
		end
		list = []
		surveys.each do |survey|
			no_tag = false
			tags.each do |tag|
				if !survey.tags.include?(tag)
					no_tag = true
					break
				end
			end
			list << Survey.get_survey_object(current_user_email, survey._id) if !no_tag
		end
		return list
	end

	#*description*: clear the cached survey object corresponding to current instance, usually called when the survey is updated, either its meta data, or questions and constrains
	#
	#*params*:
	def clear_survey_object
		Cache.write(self._id, nil)
	end


	#*description*: create a new question
	#
	#*params*:
	#* email of the user doing this operation
	#* index of page where the new question is inserted
	#* id of the question after which the new question is inserted
	#* type of new question
	#
	#*retval*:
	#* the question object
	#* ErrorEnum ::QUESTION_NOT_EXIST
	#* ErrorEnum ::UNAUTHORIZED
	#* ErrorEnum ::OVERFLOW
	def create_question(current_user_email, page_index, question_id, question_type)
		return ErrorEnum::UNAUTHORIZED if self.owner_email != current_user_email
		current_page = self.pages[page_index]
		return ErrorEnum::OVERFLOW if current_page == nil
		if question_id.to_s == "-1"
			question_index = current_page.length - 1
		else
			question_index = current_page.index(question_id)
			return ErrorEnum::QUESTION_NOT_EXIST if question_index == nil
		end
		return ErrorEnum::WRONG_QUESTION_TYPE if !Question.has_question_type(question_type)
		question = Object::const_get(question_type).new
		question.save
		current_page.insert(question_index+1, question._id.to_s)
		self.save
		return Question.get_question_object(question._id.to_s)
	end

	#*description*: update a question
	#
	#*params*:
	#* email of the user doing this operation
	#* id of the question to be updated
	#* question object
	#
	#*retval*:
	#* the question object after updated
	#* ErrorEnum ::UNAUTHORIZED
	#* ErrorEnum ::QUESTION_NOT_EXIST
	#* ErrorEnum ::WRONG_DATA_TYPE
	def update_question(current_user_email, question_id, question_obj)
		return ErrorEnum::UNAUTHORIZED if self.owner_email != current_user_email
		question = Question.find_by_id(question_id)
		return ErrorEnum::QUESTION_NOT_EXIST if question == nil
		retval = question.update_question(question_obj)
		return retval if retval != true
		question.clear_question_object
		return Question.get_question_object(question._id)
	end

	#*description*: move a question
	#
	#*params*:
	#* email of the user doing this operation
	#* id of the question to be moved
	#* index of page where the moved question is inserted
	#* id of the question after which the moved question is inserted
	#
	#*retval*:
	#* true if successfuly moved
	#* false
	#* ErrorEnum ::UNAUTHORIZED
	#* ErrorEnum ::QUESTION_NOT_EXIST
	#* ErrorEnum ::OVERFLOW
	def move_question(current_user_email, question_id_1, page_index, question_id_2)
		return ErrorEnum::UNAUTHORIZED if self.owner_email != current_user_email
		from_page = nil
		self.pages.each do |page|
			if page.include?(question_id_1)
				from_page = page
				break
			end
		end
		return ErrorEnum::QUESTION_NOT_EXIST if from_page == nil
		to_page = self.pages[page_index]
		return ErrorEnum::OVERFLOW if to_page == nil
		if question_id_2.to_s == "-1"
			question_index = -1
		else
			question_index = to_page.index(question_id_2)
			return ErrorEnum::QUESTION_NOT_EXIST if question_index == nil
		end
		question_index_to_be_delete = from_page.index(question_id_1)
		to_page.insert(question_index+1, question_id_1)
		from_page.delete_at(question_index_to_be_delete)
		return self.save
	end

	#*description*: clone a question
	#
	#*params*:
	#* email of the user doing this operation
	#* id of the question to be cloned
	#* index of page where the cloned question is inserted
	#* id of the question after which the cloned question is inserted
	#
	#*retval*:
	#* the new question object if successfully cloned
	#* ErrorEnum ::UNAUTHORIZED
	#* ErrorEnum ::QUESTION_NOT_EXIST
	#* ErrorEnum ::OVERFLOW
	def clone_question(current_user_email, question_id_1, page_index, question_id_2)
		return ErrorEnum::UNAUTHORIZED if self.owner_email != current_user_email
		from_page = nil
		self.pages.each do |page|
			if page.include?(question_id_1)
				from_page = page
				break
			end
		end
		return ErrorEnum::QUESTION_NOT_EXIST if from_page == nil
		to_page = self.pages[page_index]
		return ErrorEnum::OVERFLOW if to_page == nil
		if question_id_2.to_s == "-1"
			question_index = -1
		else
			question_index = to_page.index(question_id_2)
			return ErrorEnum::QUESTION_NOT_EXIST if question_index == nil
		end
		orig_question = Question.find_by_id(question_id_1)
		return ErrorEnum::QUESTION_NOT_EXIST if orig_question == nil
		new_question = orig_question.clone
		new_question.save
		to_page.insert(question_index+1, new_question._id.to_s)
		self.save
		return Question.get_question_object(new_question._id)
	end

	#*description*: get a question object
	#
	#*params*:
	#* email of the user doing this operation
	#* id of the question to be required
	#
	#*retval*:
	#* the question object if successfully obtained
	#* ErrorEnum ::UNAUTHORIZED
	#* ErrorEnum ::QUESTION_NOT_EXIST 
	def get_question_object(current_user_email, question_id)
		return ErrorEnum::UNAUTHORIZED if self.owner_email != current_user_email
		self.pages.each do |page|
			return Question.get_question_object(question_id) if page.include?(question_id)
		end
		return ErrorEnum::QUESTION_NOT_EXIST 
	end

	#*description*: delete a question
	#
	#*params*:
	#* email of the user doing this operation
	#* id of the question to be deleted
	#
	#*retval*:
	#* true if successfully deleted
	#* false
	#* ErrorEnum ::UNAUTHORIZED
	#* ErrorEnum ::QUESTION_NOT_EXIST 
	def delete_question(current_user_email, question_id)
		return ErrorEnum::UNAUTHORIZED if self.owner_email != current_user_email
		self.pages.each do |page|
			if page.include?(question_id)
				page.delete(question_id)
				break
			end
		end
		question = Question.find_by_id(question_id)
		return ErrorEnum::QUESTION_NOT_EXIST if question == nil
		question.clear_question_object
		question.destroy
		return self.save
	end

	#*description*: create a page
	#
	#*params*:
	#* email of the user doing this operation
	#* index of the page, after which the new page is inserted
	#
	#*retval*:
	#* true if successfully created
	#* false
	#* ErrorEnum ::UNAUTHORIZED
	#* ErrorEnum ::OVERFLOW 
	def create_page(current_user_email, page_index)
		return ErrorEnum::UNAUTHORIZED if self.owner_email != current_user_email
		return ErrorEnum::OVERFLOW if page_index < -1 or page_index > self.pages.length - 1
		self.pages.insert(page_index+1, [])
		return self.save
	end

	#*description*: show a page
	#
	#*params*:
	#* email of the user doing this operation
	#* index of the page to be shown
	#
	#*retval*:
	#* the page object if successfully obtained
	#* ErrorEnum ::UNAUTHORIZED 
	#* ErrorEnum ::OVERFLOW 
	def show_page(current_user_email, page_index)
		return ErrorEnum::UNAUTHORIZED if self.owner_email != current_user_email
		current_page = self.pages[page_index]
		return ErrorEnum::OVERFLOW if current_page == nil
		page_object = []
		current_page.each do |question_id|
			page_object << Question.get_question_object(question_id)
		end
		return page_object
	end

	#*description*: clone a page
	#
	#*params*:
	#* email of the user doing this operation
	#* index of the page to be cloned
	#* index of the page, after which the new page is inserted
	#
	#*retval*:
	#* the object of the cloned page if successfully cloned
	#* ErrorEnum ::UNAUTHORIZED 
	#* ErrorEnum ::OVERFLOW 
	#* ErrorEnum ::QUESTION_NOT_EXIST 
	def clone_page(current_user_email, page_index_1, page_index_2)
		return ErrorEnum::UNAUTHORIZED if self.owner_email != current_user_email
		current_page = self.pages[page_index_1]
		return ErrorEnum::OVERFLOW if current_page == nil
		return ErrorEnum::OVERFLOW if page_index_2 < -1 or page_index_2 > self.pages.length - 1
		new_page = []
		new_page_object = []
		current_page.each do |question_id|
			question = Question.find_by_id(question_id)
			return ErrorEnum::QUESTION_NOT_EXIST if question == nil
			new_question = question.clone
			new_question.save
			new_page << new_question._id.to_s
			new_page_object << Question.get_question_object(new_question._id)
		end
		self.pages.insert(page_index_2+1, new_page)
		self.save
		return new_page_object
	end

	#*description*: delete a page
	#
	#*params*:
	#* email of the user doing this operation
	#* index of the page to be deleted
	#
	#*retval*:
	#* true if the page is deleted
	#* false
	#* ErrorEnum ::UNAUTHORIZED
	#* ErrorEnum ::OVERFLOW
	def delete_page(current_user_email, page_index)
		return ErrorEnum::UNAUTHORIZED if self.owner_email != current_user_email
		current_page = self.pages[page_index]
		return ErrorEnum::OVERFLOW if current_page == nil
		current_page.each do |question_id|
			question = Question.find_by_id(question_id)
			question.destroy if question != nil
		end
		self.pages.delete_at(page_index)
		return self.save
	end

	#*description*: combine pages
	#
	#*params*:
	#* email of the user doing this operation
	#* index of the page, from which the pages are combined
	#* index of the page, to which the pages are combined
	#
	#*retval*:
	#* true if the page is deleted
	#* false
	#* ErrorEnum ::UNAUTHORIZED
	#* ErrorEnum ::OVERFLOW
	def combine_pages(current_user_email, page_index_1, page_index_2)
		return ErrorEnum::UNAUTHORIZED if self.owner_email != current_user_email
		return ErrorEnum::OVERFLOW if page_index_1 < 0 or page_index_1 > self.pages.length - 1
		return ErrorEnum::OVERFLOW if page_index_2 < 0 or page_index_2 > self.pages.length - 1
		self.pages[page_index_1+1..page_index_2].each do |page|
			self.pages[page_index_1] = self.pages[page_index_1] + page
			self.pages.delete(page)
		end
		return self.save
	end

	#*description*: move page
	#
	#*params*:
	#* email of the user doing this operation
	#* index of the page to be moved
	#* index of the page, after which the moved page is inserted to
	#
	#*retval*:
	#* true if the page is moved
	#* false
	#* ErrorEnum ::UNAUTHORIZED
	#* ErrorEnum ::OVERFLOW
	def move_page(current_user_email, page_index_1, page_index_2)
		return ErrorEnum::UNAUTHORIZED if self.owner_email != current_user_email
		current_page = self.pages[page_index_1]
		return ErrorEnum::OVERFLOW if current_page == nil
		return ErrorEnum::OVERFLOW if page_index_2 < -1 or page_index_2 > self.pages.length - 1
		self.pages.insert(page_index_2+1, current_page)
		self.pages.delete_at(page_index_1)
		return self.save
	end

end
