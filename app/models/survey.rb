# encoding: utf-8
require 'error_enum'
require 'quality_control_type_enum'
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
	field :user_attr_survey, :type => Boolean, default: false
	field :pages, :type => Array, default: []
	field :quota, :type => Hash, default: {"rules" => [], "is_exclusive" => true}
	field :quota_template_question_page, :type => Array, default: []
	field :logic_control, :type => Array, default: []
	field :style_setting, :type => Hash, default: {"style_sheet_name" => "",
		"has_progress_bar" => true,
		"has_question_number" => true,
		"is_one_question_per_page" => false,
		"has_advertisement" => true,
		"has_oopsdata_link" => true,
		"redirect_link" => ""}
	field :quality_control_setting, :type => Hash, default: {"allow_pageup" => false,
		"times_for_one_computer" => -1,
		"has_captcha" => false,
		"password_control" => {"password_type" => -1,
			"single_password" => "",
			"password_list" => [],
			"username_password_list" => []}}
	field :quota_stats, :type => Hash

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
	has_and_belongs_to_many :answer_auditors, class_name: "AnswerAuditor", inverse_of: :managable_survey
	has_and_belongs_to_many :entry_clerks, class_name: "EntryClerk", inverse_of: :managable_survey
	has_and_belongs_to_many :interviewers, class_name: "Interviewer", inverse_of: :managable_survey

	has_many :answers

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
			return true if page["questions"].include?(question_id)
		end
		return false
	end

	#*description*: serialize current instance into a survey object
	#
	#*params*
	#
	#*retval*:
	#* a survey object
	def to_json
		survey_obj = Hash.new
		survey_obj["_id"] = self._id.to_s
		survey_obj["created_at"] = self.created_at
		survey_obj["pages"] = Marshal.load(Marshal.dump(self.pages))
		META_ATTR_NAME_ARY.each do |attr_name|
			method_obj = self.method("#{attr_name}".to_sym)
			survey_obj[attr_name] = method_obj.call()
		end
		survey_obj["quota"] = Marshal.load(Marshal.dump(self.quota))
		survey_obj["quota_stats"] = Marshal.load(Marshal.dump(self.quota_stats))
		survey_obj["logic_control"] = Marshal.load(Marshal.dump(self.logic_control))
		survey_obj["quality_control_setting"] = Marshal.load(Marshal.dump(self.quality_control_setting))
		survey_obj["style_setting"] = Marshal.load(Marshal.dump(self.style_setting))
		survey_obj["publish_status"] = self.publish_status
		survey_obj["status"] = self.status
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
		self.save
		return self
	end

	def update_style_setting(style_setting_obj)
		self.style_setting = style_setting_obj
		self.save
		return true
	end

	def show_style_setting
		return self.style_setting
	end

	def update_quality_control_setting(quality_control_setting_obj)
		self.quality_control_setting = quality_control_setting_obj
		self.save
		return true
	end

	def show_quality_control_setting
		return self.quality_control_setting
	end

	def is_pageup_allowed
		return self.quality_control_setting["allow_pageup"]
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
	#* title of the new survey
	#
	#*retval*:
	#* the new survey instance: if successfully cloned
	#* ErrorEnum ::UNAUTHORIZED : if the user is unauthorized to do that
	def clone(title)
		# clone the meta data of the survey
		new_instance = super
		new_instance.title = title || new_instance.title

		# clone all questions
		new_instance.pages.each do |page|
			page.each_with_index do |question_id, question_index|
				question = Question.find_by_id(question_id)
				return ErrorEnum::QUESTION_NOT_EXIST if question == nil
				cloned_question = question.clone
				page[question_index] = cloned_question._id.to_s
			end
		end
		
		# the logic control should also be cloned
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
		return ErrorEnum::UNAUTHORIZED if !operator.is_admin && !operator.is_survey_auditor
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
		return ErrorEnum::UNAUTHORIZED if !operator.is_admin && !operator.is_survey_auditor
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
		return ErrorEnum::UNAUTHORIZED if self.user._id != operator._id && !operator.is_admin && !operator.is_survey_auditor
		return ErrorEnum::WRONG_PUBLISH_STATUS if ![PublishStatus::PUBLISHED, PublishStatus::UNDER_REVIEW].include?(self.publish_status)
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
	def pause(message, operator)
		return ErrorEnum::UNAUTHORIZED if self.user._id != operator._id && !operator.is_admin && !operator.is_survey_auditor
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
	def create_question(page_index, question_id, question_type)
		current_page = self.pages[page_index]
		return ErrorEnum::OVERFLOW if current_page == nil
		if question_id.to_s == "-1"
			question_index = current_page["questions"].length - 1
		elsif question_id.to_s == "0"
			question_index = -1
		else
			question_index = current_page["questions"].index(question_id)
			return ErrorEnum::QUESTION_NOT_EXIST if question_index == nil
		end
		question = Question.create_question(question_type)
		return ErrorEnum::WRONG_QUESTION_TYPE if question == ErrorEnum::WRONG_QUESTION_TYPE
		current_page["questions"].insert(question_index+1, question._id.to_s)
		self.save
		return question
	end

	def insert_template_question(page_index, question_id, template_question_id)
		template_question = TemplateQuestion.find_by_id(template_question_id)
		return ErrorEnum::TEMPLATE_QUESTION_NOT_EXIST if template_question.nil?
		
		current_page = self.pages[page_index]
		return ErrorEnum::OVERFLOW if current_page == nil
		if question_id.to_s == "-1"
			question_index = current_page["questions"].length - 1
		elsif question_id.to_s == "0"
			question_index = -1
		else
			question_index = current_page["questions"].index(question_id)
			return ErrorEnum::QUESTION_NOT_EXIST if question_index == nil
		end
		question = Question.create_template_question(template_question)
		current_page["questions"].insert(question_index+1, question._id.to_s)
		self.save
		return question
	end

	def convert_template_question_to_normal_question(question_id)
		return ErrorEnum::QUESTION_NOT_EXIST if !self.has_question(question_id)
		question = Question.find_by_id(question_id)
		return ErrorEnum::QUESTION_NOT_EXIST if question.nil?
		# quality control question in a survey cannot be updated
		question.convert_template_question_to_normal_question
		return question
	end

	def insert_quality_control_question(page_index, question_id, quality_control_question_id)
		quality_control_question = QualityControlQuestion.find_by_id(quality_control_question_id)
		return ErrorEnum::QUALITY_CONTROL_QUESTION_NOT_EXIST if quality_control_question.nil?
		
		current_page = self.pages[page_index]
		return ErrorEnum::OVERFLOW if current_page == nil
		if question_id.to_s == "-1"
			question_index = current_page["questions"].length - 1
		elsif question_id.to_s == "0"
			question_index = -1
		else
			question_index = current_page["questions"].index(question_id)
			return ErrorEnum::QUESTION_NOT_EXIST if question_index == nil
		end
		questions = Question.create_quality_control_question(quality_control_question)
		questions.each do |question|
			current_page["questions"].insert(question_index+1, question._id.to_s)
		end
		self.save
		return questions
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
	def update_question(question_id, question_obj)
		return ErrorEnum::QUESTION_NOT_EXIST if !self.has_question(question_id)
		question = Question.find_by_id(question_id)
		return ErrorEnum::QUESTION_NOT_EXIST if question.nil?
		return ErrorEnum::WRONG_QUESTION_CLASS if question.question_class == "quality_control" || question.question_class == "template"
		# quality control question in a survey cannot be updated
		retval = question.update_question(question_obj)
		return retval if retval != true
		return question
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
	def move_question(question_id_1, page_index, question_id_2)
		from_page = nil
		self.pages.each do |page|
			if page["questions"].include?(question_id_1)
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
			question_index = to_page["questions"].index(question_id_2)
			return ErrorEnum::QUESTION_NOT_EXIST if question_index == nil
		end
		question_index_to_be_delete = from_page["questions"].index(question_id_1)
		to_page["questions"].insert(question_index+1, question_id_1)
		from_page["questions"].delete_at(question_index_to_be_delete)
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
	def clone_question(question_id_1, page_index, question_id_2)
		from_page = nil
		self.pages.each do |page|
			if page["questions"].include?(question_id_1)
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
		return ErrorEnum::WRONG_QUESTION_CLASS if orig_question.question_class == "quality_control" || orig_question.question_class == "template"
		new_question = orig_question.clone
		to_page["questions"].insert(question_index+1, new_question._id.to_s)
		self.save
		return new_question
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
	def get_question_inst(question_id)
		return ErrorEnum::QUESTION_NOT_EXIST if !self.has_question(question_id)
		question = Question.find_by_id(question_id)
		return ErrorEnum::QUESTION_NOT_EXIST if question.nil?
		return question
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
	def delete_question(question_id)
		question = Question.find_by_id(question_id)
		return ErrorEnum::QUESTION_NOT_EXIST if question.nil?
		# find out other matching questions if the question to be deleted is a matching question
		if question.question_class == 2
			quality_control_question = QualityControlQuestion.find_by_id(question.reference_id)
			if quality_control_question.quality_control_type == QualityControlTypeEnum::MATCHING
				matching_question_ids = MatchingQuestion.get_matching_question_ids(quality_control_question._id)
				self.pages.each do |page|
					page["questions"].each do |q_id|
						q = Question.find_by_id(q_id)
						if q.nil? || matching_question_ids.include?(q.reference_id)
							page["questions"].delete(q_id)
							q.destroy
							q.clear_question_object
						end
					end
				end
				self.save
			end
		end
		# not a matching quality control question
		find_question = false
		self.pages.each do |page|
			if page["questions"].include?(question_id)
				page["questions"].delete(question_id)
				find_question = true
				break
			end
		end
		return ErrorEnum::QUESTION_NOT_EXIST if !find_question
		self.save
		question.clear_question_object
		return question.destroy
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
	def create_page(page_index, page_name)
		return ErrorEnum::OVERFLOW if page_index < -1 or page_index > self.pages.length - 1
		new_page = {name: page_name, questions: []}
		self.pages.insert(page_index+1, new_page)
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
	def show_page(page_index)
		current_page = self.pages[page_index]
		return ErrorEnum::OVERFLOW if current_page.nil?
		page_object = {name: current_page["name"], questions: []}
		current_page["questions"].each do |question_id|
			page_object[:questions] << Question.get_question_object(question_id)
		end
		return page_object
	end

	def update_page(page_index, page_name)
		current_page = self.pages[page_index]
		return ErrorEnum::OVERFLOW if current_page.nil?
		current_page["name"] = page_name
		return self.save
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
	def clone_page(page_index_1, page_index_2)
		current_page = self.pages[page_index_1]
		return ErrorEnum::OVERFLOW if current_page == nil
		return ErrorEnum::OVERFLOW if page_index_2 < -1 or page_index_2 > self.pages.length - 1
		new_page = {"name" => current_page["name"], "questions" => []}
		new_page_obj = {"name" => current_page["name"], "questions" => []}
		current_page["questions"].each do |question_id|
			question = Question.find_by_id(question_id)
			return ErrorEnum::QUESTION_NOT_EXIST if question == nil
			new_question = question.clone
			new_page["questions"] << new_question._id.to_s
			new_page_obj["questions"] << new_question
		end
		self.pages.insert(page_index_2+1, new_page)
		self.save
		return new_page_obj
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
	def delete_page(page_index)
		current_page = self.pages[page_index]
		return ErrorEnum::OVERFLOW if current_page.nil?
		current_page["questions"].each do |question_id|
			question = Question.find_by_id(question_id)
			question.destroy if !question.nil?
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
	def combine_pages(page_index_1, page_index_2)
		return ErrorEnum::OVERFLOW if page_index_1 < 0 or page_index_1 > self.pages.length - 1
		return ErrorEnum::OVERFLOW if page_index_2 < 0 or page_index_2 > self.pages.length - 1
		self.pages[page_index_1+1..page_index_2].each do |page|
			self.pages[page_index_1]["questions"] = self.pages[page_index_1]["questions"] + page["questions"]
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
	def move_page(page_index_1, page_index_2)
		current_page = self.pages[page_index_1]
		return ErrorEnum::OVERFLOW if current_page == nil
		return ErrorEnum::OVERFLOW if page_index_2 < -1 or page_index_2 > self.pages.length - 1
		self.pages.insert(page_index_2+1, current_page)
		self.pages.delete_at(page_index_1)
		return self.save
	end

	def set_user_attr_survey(user_attr_survey)
		self.user_attr_survey = user_attr_survey.to_s == "true"
		self.save
		return true
	end

	def self.get_user_attr_survey
		survey = Survey.where(:user_attr_survey => true)[0]
		return [] if survey.nil?
		questions = []
		survey.pages.each do |page|
			page["questions"].each do |q_id|
				q = Question.find_by_id(q_id)
				next if q.nil? || q.question_class != 1
				questions << q
			end
		end
		return {survey._id.to_s => questions}
	end

	# return all the surveys that are published and are active
	# it is needed to send emails and invite volunteers for these surveys
	def self.get_published_active_surveys
		
	end

	def check_password(username, password, current_user)
		case self.quality_control_setting["password_control"]["password_type"]
		when -1
			return true
		when 0
			if self.quality_control_setting["password_control"]["single_password"] == password
				return true
			else
				return ErrorEnum::WRONG_PASSWORD
			end
		when 1
			list = self.quality_control_setting["password_control"]["password_list"]
			password_element = list.select { |ele| ele["content"] == password }[0]
		when 2
			list = self.quality_control_setting["password_control"]["username_password_list"]
			password_element = list.select { |ele| ele["content"] == [username, password] }[0]
		end
		if password_element.nil?
			return ErrorEnum::WRONG_PASSWORD
		elsif password_element["used"] = false
			password_element["used"] = true
			self.save
			return true
		else
			answer = Answer.find_by_password(username, password)
			return ErrorEnum::ANSWER_NOT_EXIST if answer.nil?
			user = answer.user
			return ErrorEnum::REQUIRE_LOGIN if user.is_registered
			user.answers.delete(answer)
			answer.user = current_user
			return answer
		end
	end

	def add_quota_template_question(template_question_id)
		template_question = TemplateQuestion.find_by_id(template_question_id)
		return ErrorEnum::TEMPLATE_QUESTION_NOT_EXIST if template_question.nil?
		return true if self.quota_template_question_page.include?(question._id.to_s)
		question = Question.create_template_question(template_question)
		self.quota_template_question_page << question._id.to_s
		return self.save
	end

	def remove_quota_template_question(template_question_id)
		self.quota_template_question_page.each do |q_id|
			question = Question.find_by_id(q_id)
			if question.reference_id == template_question_id
				self.quota_template_question_page.delete(q_id)
				return self.save
			end
		end
	end

	def show_quota
		return Marshal.load(Marshal.dump(self.quota))
	end

	def show_quota_rule(quota_rule_index)
		quota = Quota.new(self.quota)
		return quota.show_rule(quota_rule_index)
	end

	def add_quota_rule(quota_rule)
		quota = Quota.new(self.quota)
		return quota.add_rule(quota_rule, self)
	end

	def update_quota_rule(quota_rule_index, quota_rule)
		quota = Quota.new(self.quota)
		return quota.update_rule(quota_rule_index, quota_rule, self)
	end

	def delete_quota_rule(quota_rule_index)
		quota = Quota.new(self.quota)
		return quota.delete_rule(quota_rule_index, self)
	end

	def refresh_quota_stats
		answers = self.answers
		quota_stats = {"quota_satisfied" => true, "answer_number" => []}
		self.quota["rules"].length.times { quota_stats["answer_number"] << 0 }
		answers.each do |answer|
			self.quota["rules"].each_with_index do |rule, rule_index|
				if answer.satisfy_quota_conditions(rule["conditions"])
					quota_stats["answer_number"][rule_index] = quota_stats["answer_number"][rule_index] + 1
				end
			end
		end
		quota_stats["answer_number"].each_with_index do |answer_number, index|
			required_number = self.quota["rules"][index]["amount"]
			quota_stats["quota_satisfied"] = quota_stats["quota_satisfied"] && answer_number >= required_number
		end
		self.quota_stats = quota_stats
		self.save
	end

	def set_exclusive(is_exclusive)
		quota = Quota.new(self.quota)
		return quota.set_exclusive(is_exclusive, self)
	end

	def get_exclusive
		return self.quota["is_exclusive"]
	end

	def show_logic_control
		return Marshal.load(Marshal.dump(self.logic_control))
	end

	def show_logic_control_rule(logic_control_rule_index)
		logic_control = LogicControl.new(self.logic_control)
		return logic_control.show_rule(logic_control_rule_index)
	end

	def add_logic_control_rule(logic_control_rule)
		logic_control = LogicControl.new(self.logic_control)
		return logic_control.add_rule(logic_control_rule, self)
	end

	def update_logic_control_rule(logic_control_rule_index, logic_control_rule)
		logic_control = LogicControl.new(self.logic_control)
		return logic_control.update_rule(logic_control_rule_index, logic_control_rule, self)
	end

	def delete_logic_control_rule(logic_control_rule_index)
		logic_control = LogicControl.new(self.logic_control)
		return logic_control.delete_rule(logic_control_rule_index, self)
	end

	class Quota
		CONDITION_TYPE = (0..4).to_a
		def initialize(quota)
			@is_exclusive = !!quota["is_exclusive"]
			@rules = Marshal.load(Marshal.dump(quota["rules"]))
		end

		def show_rule(rule_index)
			return ErrorEnum::QUOTA_RULE_NOT_EXIST if @rules.length <= rule_index
			return Marshal.load(Marshal.dump(@rules[rule_index]))
		end

		def add_rule(rule, survey)
			# check errors
			rule["amount"] = rule["amount"].to_i
			return ErrorEnum::WRONG_QUOTA_RULE_AMOUNT if rule["amount"].to_i <= 0
			rule["conditions"].each do |condition|
				condition["condition_type"] = condition["condition_type"].to_i
				return ErrorEnum::WRONG_QUOTA_RULE_CONDITION_TYPE if !CONDITION_TYPE.include?(condition["condition_type"])
			end
			# add the rule
			@rules << rule
			survey.quota = self.serialize
			survey.save
			# add the template questions corresponding to the new rule
			survey.quota["rules"][-1]["conditions"].each do |condition|
				self.add_quota_template_question(condition["name"]) if condition["condition_type"] == 0
			end
			return survey.quota
		end

		def delete_rule(rule_index, survey)
			# check errors
			return ErrorEnum::QUOTA_RULE_NOT_EXIST if @rules.length <= rule_index
			# remove the template questions corresponding to the old quota rule
			survey.quota["rules"][rule_index]["conditions"].each do |condition|
				self.remove_quota_template_question(condition["name"]) if condition["condition_type"] == 0
			end
			# delete the rule
			@rules.delete_at(rule_index)
			survey.quota = self.serialize
			return survey.save
		end

		def update_rule(rule_index, rule, survey)
			# check errors
			rule["amount"] = rule["amount"].to_i
			return ErrorEnum::QUOTA_RULE_NOT_EXIST if @rules.length <= rule_index
			return ErrorEnum::WRONG_QUOTA_RULE_AMOUNT if rule["amount"].to_i <= 0
			rule["conditions"].each do |condition|
				condition["condition_type"] = condition["condition_type"].to_i
				return ErrorEnum::WRONG_QUOTA_RULE_CONDITION_TYPE if !CONDITION_TYPE.include?(condition["condition_type"].to_i)
			end
			# remove the template questions corresponding to the old quota rule
			survey.quota["rules"][rule_index]["conditions"].each do |condition|
				self.remove_quota_template_question(condition["name"]) if condition["condition_type"] == 0
			end
			# update the rule
			@rules[rule_index] = rule
			survey.quota = self.serialize
			survey.save
			# add the template questions corresponding to the new quota rule
			survey.quota["rules"][rule_index]["conditions"].each do |condition|
				self.add_quota_template_question(condition["name"]) if condition["condition_type"].to_i == 0
			end
			return survey.quota
		end

		def set_exclusive(is_exclusive, survey)
			@is_exclusive = !!is_exclusive
			survey.quota = self.serialize
			return survey.save
		end

		def serialize
			quota_object = {}
			quota_object["rules"] = @rules
			quota_object["is_exclusive"] = @is_exclusive
			return quota_object
		end
	end

	class LogicControl
		RULE_TYPE = (0..6).to_a
		def initialize(logic_control)
			@rules = logic_control
		end

		def show_rule(rule_index)
			return ErrorEnum::LOGIC_RULE_NOT_EXIST if @rules.length <= rule_index
			return Marshal.load(Marshal.dump(@rules[rule_index]))
		end

		def add_rule(rule, survey)
			rule["rule_type"] = rule["rule_type"].to_i
			return ErrorEnum::WRONG_LOGIC_CONTROL_TYPE if !RULE_TYPE.include?(rule["rule_type"])
			@rules << rule
			survey.logic_control = @rules
			survey.save
			return survey.logic_control
		end

		def delete_rule(rule_index, survey)
			return ErrorEnum::LOGIC_CONTROL_RULE_NOT_EXIST if @rules.length <= rule_index
			@rules.delete_at(rule_index)
			survey.logic_control = @rules
			return survey.save
		end

		def update_rule(rule_index, rule, survey)
			return ErrorEnum::LOGIC_CONTROL_RULE_NOT_EXIST if @rules.length <= rule_index
			rule["rule_type"] = rule["rule_type"].to_i
			return ErrorEnum::WRONG_LOGIC_CONTROL_TYPE if !RULE_TYPE.include?(rule["rule_type"])
			@rules[rule_index] = rule
			survey.logic_control = @rules
			survey.save
			return survey.logic_control
		end
	end
end
