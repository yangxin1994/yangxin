# encoding: utf-8
require 'error_enum'
require 'publish_status'
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
	include Mongoid::Timestamps
	field :title, :type => String, default: "调查问卷主标题"
	field :subtitle, :type => String, default: "调查问卷副标题"
	field :welcome, :type => String, default: "调查问卷欢迎语"
	field :closing, :type => String, default: "调查问卷结束语"
	field :header, :type => String, default: "调查问卷页眉"
	field :footer, :type => String, default: "调查问卷页脚"
	field :description, :type => String, default: "调查问卷描述"
	field :status, :type => Integer, default: 0
	# can be 1 (closed), 2 (under review), 4 (paused), 8 (published)
	field :publish_status, :type => Integer, default: 1
	field :pages, :type => Array, default: Array.new
	field :quota, :type => Hash, default: {"rules" => [], "is_exclusive" => true}
	field :constrains, :type => Array, default: Array.new

	belongs_to :user
	has_and_belongs_to_many :tags do
		def has_tag?(content)
			@target.each do |tag|
				return true if tag.content == content
			end
			return false
		end
	end
	has_many :publish_status_historys

	scope :normal, lambda { where(:status.gt => -1) }
	scope :deleted, lambda { where(:status => -1) }


	before_save :clear_survey_object
	before_update :clear_survey_object
	before_destroy :clear_survey_object

	META_ATTR_NAME_ARY = %w[title subtitle welcome closing header footer description]

	public


	#*description*: judge whether this survey has a question
	#
	#*params*
	#* id of the question
	#
	#*retval*:
	#* boolean value
	def has_question(question_id)
		self.pages.each do |page|
			return true if page.include?(question_id)
		end
		return false
	end

	#*description*: serialize current instance into a survey object
	#
	#*params*
	#
	#*retval*:
	#* a survey object
	def serialize
		survey_obj = Hash.new
		survey_obj["_id"] = self._id.to_s
		survey_obj["created_at"] = self.created_at
		survey_obj["pages"] = Marshal.load(Marshal.dump(self.pages))
		META_ATTR_NAME_ARY.each do |attr_name|
			method_obj = self.method("#{attr_name}".to_sym)
			survey_obj[attr_name] = method_obj.call()
		end
		survey_obj["quota"] = Marshal.load(Marshal.dump(self.quota))
		return survey_obj
	end

	#*description*: find a survey by its id. return nil if cannot find
	#
	#*params*:
	#* id of the survey to be found
	#
	#*retval*:
	#* the survey instance found, or nil if cannot find
	def self.find_by_id(survey_id)
		return Survey.where(:_id => survey_id).first
	end


	def self.list(status, publish_status, tags)
		survey_list = []
		case status
		when "all"
			surveys = Survey.all
		when "deleted"
			surveys = Survey.deleted
		when "normal"
			surveys = Survey.normal
		end
		surveys.each do |survey|
			if tags.nil? || tags.empty? || survey.has_one_tag_of(tags)
				if publish_status.nil? || survey.publish_status & publish_status
					survey_list << survey
				end
			end
		end
		return survey_list
	end

	def has_one_tag_of(tags)
		survey_tags = self.tags.map {|tag_inst| tag_inst.content}
		return !(survey_tags & tags).empty?
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
	def save_meta_data(survey_obj)
		# this is an existing survey
		META_ATTR_NAME_ARY.each do |attr_name|
			method_obj = self.method("#{attr_name}=".to_sym)
			method_obj.call(survey_obj[attr_name])
		end
		return self.save
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
	def delete
		### stop publish
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
	def recover
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
	def clear
		return ErrorEnum::SURVEY_NOT_EXIST if self.status != -1
		self.tags.each do |tag|
			tag.destroy if tag.surveys.length == 1
		end
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
	def clone(current_user)
		return ErrorEnum::UNAUTHORIZED if self.owner_email != current_user.email

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
		
	#*description*: add a tag to the survey
	#
	#*params*:
	#* email of the user doing this operation
	#* tag to be added
	#
	#*retval*:
	#* the survey object: if successfully cleared
	#* ErrorEnum ::UNAUTHORIZED : if the user is unauthorized to do that
	def add_tag(tag)
		return ErrorEnum::TAG_EXIST if self.tags.has_tag?(tag)
		self.tags << Tag.get_or_create_new(tag)
		return true
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
	def remove_tag(tag)
		return ErrorEnum::TAG_NOT_EXIST if !self.tags.has_tag?(tag)
		tag_inst = Tag.find_by_content(tag)
		self.tags.delete(tag_inst)
		tag_inst.destroy if tag_inst.surveys.length == 0
		return true
	end

	#*description*: submit a survey to the administrator for reviewing
	#
	#*params*:
	#* the user doing this operation
	#
	#*retval*:
	#* true
	#* ErrorEnum ::UNAUTHORIZED : if the user is unauthorized to do that
	#* ErrorEnum ::WRONG_PUBLISH_STATUS
	def submit(message, operator)
		return ErrorEnum::UNAUTHORIZED if self.user._id != operator._id && !operator.is_admin
		return ErrorEnum::WRONG_PUBLISH_STATUS if ![PublishStatus::CLOSED, PublishStatus::PAUSED].include?(self.publish_status)
		before_publish_status = self.publish_status
		self.update_attributes(:publish_status => PublishStatus::UNDER_REVIEW)
		publish_status_history = PublishStatusHistory.create_new(operator._id, before_publish_status, PublishStatus::UNDER_REVIEW, message)
		self.publish_status_historys << publish_status_history
		return true
	end

	#*description*: reject a survey
	#
	#*params*:
	#* the user doing this operation
	#
	#*retval*:
	#* true
	#* ErrorEnum ::UNAUTHORIZED : if the user is unauthorized to do that
	#* ErrorEnum ::WRONG_PUBLISH_STATUS
	def reject(message, operator)
		return ErrorEnum::UNAUTHORIZED if !operator.is_admin
		return ErrorEnum::WRONG_PUBLISH_STATUS if self.publish_status != PublishStatus::UNDER_REVIEW
		before_publish_status = self.publish_status
		self.update_attributes(:publish_status => PublishStatus::PAUSED)
		publish_status_history = PublishStatusHistory.create_new(operator._id, before_publish_status, PublishStatus::PAUSED, message)
		self.publish_status_historys << publish_status_history
		return true
	end

	#*description*: publish a survey
	#
	#*params*:
	#* the user doing this operation
	#
	#*retval*:
	#* true
	#* ErrorEnum ::UNAUTHORIZED : if the user is unauthorized to do that
	#* ErrorEnum ::WRONG_PUBLISH_STATUS
	def publish(message, operator)
		return ErrorEnum::UNAUTHORIZED if !operator.is_admin
		return ErrorEnum::WRONG_PUBLISH_STATUS if self.publish_status != PublishStatus::UNDER_REVIEW
		before_publish_status = self.publish_status
		self.update_attributes(:publish_status => PublishStatus::PUBLISHED)
		publish_status_history = PublishStatusHistory.create_new(operator._id, before_publish_status, PublishStatus::PUBLISHED, message)
		self.publish_status_historys << publish_status_history
		return true
	end

	#*description*: close a survey
	#
	#*params*:
	#* the user doing this operation
	#
	#*retval*:
	#* true
	#* ErrorEnum ::UNAUTHORIZED : if the user is unauthorized to do that
	#* ErrorEnum ::WRONG_PUBLISH_STATUS
	def close(message, operator)
		return ErrorEnum::UNAUTHORIZED if self.user._id != operator._id && !operator.is_admin
		before_publish_status = self.publish_status
		self.update_attributes(:publish_status => PublishStatus::CLOSED)
		publish_status_history = PublishStatusHistory.create_new(operator._id, before_publish_status, PublishStatus::CLOSED, message)
		self.publish_status_historys << publish_status_history
		return true
	end

	#*description*: pause a survey
	#
	#*params*:
	#* the user doing this operation
	#
	#*retval*:
	#* true
	#* ErrorEnum ::UNAUTHORIZED : if the user is unauthorized to do that
	#* ErrorEnum ::WRONG_PUBLISH_STATUS
	def pause(current_user, message)
		return ErrorEnum::UNAUTHORIZED if self.user._id != operator._id && !operator.is_admin
		return ErrorEnum::WRONG_PUBLISH_STATUS if ![PublishStatus::PUBLISHED, PublishStatus::UNDER_REVIEW].include?(self.publish_status)
		before_publish_status = self.publish_status
		self.update_attributes(:publish_status => PublishStatus::PAUSED)
		publish_status_history = PublishStatusHistory.create_new(operator._id, before_publish_status, PublishStatus::PAUSED, message)
		self.publish_status_historys << publish_status_history
		return true
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
	def create_question(current_user, page_index, question_id, question_type)
		return ErrorEnum::UNAUTHORIZED if self.owner_email != current_user.email
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
	def update_question(current_user, question_id, question_obj)
		return ErrorEnum::UNAUTHORIZED if self.owner_email != current_user.email
		return ErrorEnum::QUESTION_NOT_EXIST if !self.has_question(question_id)
		question = Question.find_by_id(question_id)
		return ErrorEnum::QUESTION_NOT_EXIST if question == nil
		# quality control question in a survey cannot be updated
		return ErrorEnum::UNAUTHORIZED if questiion.is_quality_control_question
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
	def move_question(current_user, question_id_1, page_index, question_id_2)
		return ErrorEnum::UNAUTHORIZED if self.owner_email != current_user.email
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
	def clone_question(current_user, question_id_1, page_index, question_id_2)
		return ErrorEnum::UNAUTHORIZED if self.owner_email != current_user.email
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
	def get_question_object(current_user, question_id)
		return ErrorEnum::UNAUTHORIZED if self.owner_email != current_user.email
		return ErrorEnum::QUESTION_NOT_EXIST if !self.has_question(question_id)
		return Question.get_question_object(question_id)
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
	def delete_question(current_user, question_id)
		return ErrorEnum::UNAUTHORIZED if self.owner_email != current_user.email
		find_question = false
		self.pages.each do |page|
			if page.include?(question_id)
				page.delete(question_id)
				find_question = true
				break
			end
		end
		return ErrorEnum::QUESTION_NOT_EXIST if !find_question
		return self.save
		question = Question.find_by_id(question_id)
		return ErrorEnum::QUESTION_NOT_EXIST if question == nil
		question.clear_question_object
		question.destroy
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
	def create_page(current_user, page_index)
		return ErrorEnum::UNAUTHORIZED if self.owner_email != current_user.email
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
	def show_page(current_user, page_index)
		return ErrorEnum::UNAUTHORIZED if self.owner_email != current_user.email
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
	def clone_page(current_user, page_index_1, page_index_2)
		return ErrorEnum::UNAUTHORIZED if self.owner_email != current_user.email
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
	def delete_page(current_user, page_index)
		return ErrorEnum::UNAUTHORIZED if self.owner_email != current_user.email
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
	def combine_pages(current_user, page_index_1, page_index_2)
		return ErrorEnum::UNAUTHORIZED if self.owner_email != current_user.email
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
	def move_page(current_user, page_index_1, page_index_2)
		return ErrorEnum::UNAUTHORIZED if self.owner_email != current_user.email
		current_page = self.pages[page_index_1]
		return ErrorEnum::OVERFLOW if current_page == nil
		return ErrorEnum::OVERFLOW if page_index_2 < -1 or page_index_2 > self.pages.length - 1
		self.pages.insert(page_index_2+1, current_page)
		self.pages.delete_at(page_index_1)
		return self.save
	end

	def show_quota(current_user)
		return ErrorEnum::UNAUTHORIZED if self.owner_email != current_user.email && !current_user.is_admin
		return Marshal.load(Marshal.dump(self.quota))
	end

	def add_quota_rule(current_user, quota_rule)
		return ErrorEnum::UNAUTHORIZED if self.owner_email != current_user.email && !current_user.is_admin
		quota = Quota.new(self.quota)
		return quota.add_rule(quota_rule, self)
	end

	def update_quota_rule(current_user, quota_rule_index, quota_rule)
		return ErrorEnum::UNAUTHORIZED if self.owner_email != current_user.email && !current_user.is_admin
		quota = Quota.new(self.quota)
		return quota.update_rule(quota_rule_index, quota_rule, self)
	end

	def delete_quota_rule(current_user, quota_rule_index)
		return ErrorEnum::UNAUTHORIZED if self.owner_email != current_user.email && !current_user.is_admin
		quota = Quota.new(self.quota)
		return quota.delete_rule(quota_rule_index, self)
	end

	def set_exclusive(current_user, is_exclusive)
		return ErrorEnum::UNAUTHORIZED if self.owner_email != current_user.email && !current_user.is_admin
		quota = Quota.new(self.quota)
		return quota.set_exclusive(is_exclusive, self)
	end

	class Quota
		attr_accessor :rules, :is_exclusive
		CONDITION_TYPE = (0..4).to_a
		def initialize(quota)
			@is_exclusive = !!quota.is_exclusive
			@rules = Marshal.load(Marshal.dump(quota.rules))
		end

		def add_rule(rule, survey)
			return ErrorEnum::WRONG_QUOTA_RULE_AMOUNT if rule["amount"].class != Interger
			rule["conditions"].each do |condition|
				return ErrorEnum::WRONG_QUOTA_RULE_CONDITION_TYPE if !CONDITION_TYPE.include(condition["condition_type"])
			end
			@rules << rule
			survey.quota = self.serialize
			survey.save
			return survey.quota
		end

		def delete_rule(rule_index, survey)
			return ErrorEnum::QUOTA_RULE_NOT_EXIST if @rules.length <= rule_index
			@rules.delete_at(rule_index)
			survey.quota = self.serialize
			survey.save
			return survey.quota
		end

		def update_rule(rule_index, rule, survey)
			return ErrorEnum::QUOTA_RULE_NOT_EXIST if @rules.length <= rule_index
			return ErrorEnum::WRONG_QUOTA_RULE_AMOUNT if rule["amount"].class != Interger
			rule["conditions"].each do |condition|
				return ErrorEnum::WRONG_QUOTA_RULE_CONDITION_TYPE if !CONDITION_TYPE.include(condition["condition_type"])
			end
			@rules[rule_index] = rule
			survey.quota = self.serialize
			survey.save
			return survey.quota
		end

		def set_exclusive(is_exclusive, survey)
			@is_exclusive = !!is_exclusive
			survey.quota = self.serialize
			survey.save
			return survey.quota
		end

		def serialize
			quota_object = {}
			quota_object["rules"] = @rules
			quota_object["is_exclusive"] = @is_exclusive
			return quota_object
		end
	end
end
