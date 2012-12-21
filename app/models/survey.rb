# encoding: utf-8
require 'error_enum'
require 'quality_control_type_enum'
require 'quill_common'
require 'securerandom'
require 'csv'
#The survey object has the following structure
# {
#  "owner_meail" : email of the owner user(string),
#  "survey_id" : id of the survey(string),
#  "title" : title of the survey(string),
#  "subtitle" : subtitle of the survey(string),
#  "welcome" : welcome of the survey(string),
#  "closing" : closing of the survey(string),
#  "header" : header of the survey(string),
#  "footer" : footer of the survey(string),
#  "description" : description of the survey(string),
#  "created_at" : create time of the survey(integer),
#  "constrains": an array of constrains
#  "pages" : 2D array, each nested array is a page and each element is a Question id(2D array)
# }
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
	# indicates whether this is a new survey that has not been edited
	field :new_survey, :type => Boolean, default: true
	field :alt_new_survey, :type => Boolean, default: false
	# can be 0 (normal), or -1 (deleted)
	field :status, :type => Integer, default: 0 
	# can be 1 (closed), 2 (under review), 8 (published), the 4(pause) has been removed
	field :publish_status, :type => Integer, default: 1
	field :user_attr_survey, :type => Boolean, default: false
	field :pages, :type => Array, default: [{"name" => "", "questions" => []}]
	field :quota, :type => Hash, default: {"rules" => ["conditions" => [], "amount" => 100, "finished_count" => 0, "submitted_count" => 0], "is_exclusive" => true, "quota_satisfied" => false, "finished_count" => 0 }
	# field :quota_stats, :type => Hash, default: {"quota_satisfied" => false, "answer_number" => [0]}
	field :filters, :type => Array, default: []
	field :filters_stats, :type => Array, default: []
	field :logic_control, :type => Array, default: []
	field :style_setting, :type => Hash, default: {"style_sheet_name" => "",
		"has_progress_bar" => true,
		"has_question_number" => true,
		"is_one_question_per_page" => false,
		"has_advertisement" => true,
		"has_oopsdata_link" => true,
		"redirect_link" => "",
		"allow_pageup" => false}
	field :access_control_setting, :type => Hash, default: {"times_for_one_computer" => -1,
		"has_captcha" => false,
		"ip_restrictions" => [],
		"password_control" => {"password_type" => -1,
			"single_password" => "",
			"password_list" => [],
			"username_password_list" => []}}
	# the type of inserting quality control question
	#  0 for not inserting
	#  1 for inserting manually
	#  2 for inserting randomly
	field :quality_control_questions_type, :type => Integer, default: 0
	field :quality_control_questions_ids, :type => Array, default: []
	field :deadline, :type => Integer
	field :is_star, :type => Boolean, :default => false
	field :point, :type => Integer, :default => 0
	field :spread_point, :type => Integer, :default => 0
	field :spreadable, :type => Boolean, :default => false
	# reward: 0: nothing, 1: prize, 2: point 
	field :reward, :type => Integer, :default => 0

	field :show_in_community, :type => Boolean, default: false

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
	has_and_belongs_to_many :answer_auditors, class_name: "User", inverse_of: :answer_auditor_allocated_surveys
	has_and_belongs_to_many :entry_clerks, class_name: "User", inverse_of: :entry_clerk_allocated_surveys
	has_and_belongs_to_many :interviewers, class_name: "User", inverse_of: :interviewer_allocated_surveys

	has_many :answers
	has_many :email_histories

	has_many :survey_spreads

	belongs_to :lottery

	has_many :export_results
	has_many :analysis_results
	has_many :report_results
	has_many :report_mockups


	scope :all_but_new, lambda { where(:new_survey => false) }
	scope :normal, lambda { where(:status.gt => -1) }
	scope :normal_but_new, lambda { where(:status.gt => -1, :new_survey => false) }
	scope :deleted, lambda { where(:status => -1) }
	scope :deleted_but_new, lambda { where(:status => -1, :new_survey => false) }
	# scope for star
	scope :stars, where(:status.gt => -1, :is_star => true)

	scope :in_community, lambda { where(:show_in_community => true) }

	before_create :set_new

	before_save :clear_survey_object
	before_save :update_new
	before_update :clear_survey_object
	before_destroy :clear_survey_object

	META_ATTR_NAME_ARY = %w[title subtitle welcome closing header footer description]

	public
	
	def all_questions
		q = []
		# quota_template_question_page.each do |page|
		#   q << page[:questions]
		# end
		pages.each do |page|
			q += page["questions"]
		end
		q.collect { |i| Question.find(i) }
	end

	def all_questions_id
		return (pages.map {|p| p["questions"]}).flatten
	end

	def all_questions_type
		q = []
		all_questions.each do |a|
			q << Kernel.const_get(QuestionTypeEnum::QUESTION_TYPE_HASH["#{a.question_type}"] + "Io").new(a)
		end
		q
	end

	#----------------------------------------------
	#  
	#     file export interface
	#
	#++++++++++++++++++++++++++++++++++++++++++++++

	def to_csv(path = "public/import/test.csv")
		c = CSV.open(path, "w") do |csv|
			csv << csv_header
			answer_content.each do |a|
			csv << a
			end
		end
	end

	def get_csv_header(path = "public/import/test.csv")
		c = CSV.open(path, "w") do |csv|
			csv << csv_header
		end
	end


	def to_spss
		return ErrorEnum::FILTER_NOT_EXIST if filter_index >= self.filters.length
		task_id = TaskClient.create_task({ task_type: "result",
											host: "localhost",
											port: Rails.application.config.service_port,
											params: { result_type: "spss",
																survey_id: self._id,
																filter_index: filter_index,
																include_screened_answer: include_screened_answer} })
		return task_id
	end

	def to_spss_job(filter_index, include_screened_answer, task_id)
    # a = get_answers(filter_index, include_screened_answer, task_id)
    # as = []
    # result = Result.find_by_task_id task_id
    # q = self.all_questions_type
    # p "========= 准备完毕 ========="
    # result.answers_count = a.size
    # a.each_with_index do |answer, index|
    #   line_answer = []
    #   i = -1
    #     answer.answer_content.each do |k, v|
    #       line_answer += q[i += 1].answer_content(v)
    #     end
    #   # set_status({"export_answers_progress" => (index + 1) * 1.0 / result.answers_count })
      
    #   p "========= 转出 #{index} 条 进度 #{set_status["export_answers_progress"]} =========" if index%10 == 0
    #   as << line_answer
    # end
    # result.answer_contents = as
    # result.save
    #     {'spss_data' => {"spss_header" => spss_header,
    #                      "answer_contents" => as,
    #                      "header_name" => csv_header,
    #                      "result_key" => @result.result_key}.to_yaml}
	end

  def excel_header
    headers =[]
    self.all_questions.each_with_index do |e, i|
      headers += e.excel_header("q#{i+1}")
    end
    headers
  end

  def csv_header
    headers = []
    self.all_questions.each_with_index do |e, i|
  	  headers += e.csv_header("q#{i+1}")
    end
    headers
  end

	def answer_import(path = "public/import/test.csv")
		q = []
		batch = []
		all_questions.each do |a|
			q << Kernel.const_get(QuestionTypeEnum::QUESTION_TYPE_HASH["#{a.question_type}"] + "Io").new(a)
		end 
		CSV.foreach(path, :headers => true) do |row|
			row = row.to_hash
			line_answer = {}
			quota_qustions_count = quota_qustions.size
			q.each_with_index do |e, i|
				#q = Kernel.const_get(QuestionTypeEnum::QUESTION_TYPE_HASH["#{e.question_type}"] + "Io").new(e)
				header_prefix = "q#{i + 1}"
				line_answer.merge! e.answer_import(row, header_prefix)
			end
			batch << {:answer_content => line_answer, :survey => self._id}
		end
		Survey.collection.insert(batch)
		return self.save
	end

	#--
	# update deadline and create a survey_deadline_job
	#++
	# Example:
	#
	# instance.update_deadline(Time.now+3.days)
	def update_deadline(time)
		time = time.to_i
		return ErrorEnum::SURVEY_DEADLINE_ERROR if time <= Time.now.to_i && time != -1
		self.deadline = time == -1 ? nil : time
		return ErrorEnum::UNKNOWN_ERROR unless self.save
		retval = TaskClient.destroy_task("survey_deadline", {survey_id: self._id})
		return ErrorEnum::TASK_DESTROY_FAILED if retval == ErrorEnum::TASK_DESTROY_FAILED
		#create or update job
		if !self.deadline.nil?
			task_id = TaskClient.create_task({ task_type: "survey_deadline",
											host: "localhost",
											port: Rails.application.config.service_port,
											executed_at: time,
											params: { survey_id: self._id} })
		end
		return true
	end

	def update_star(is_star)
		self.is_star = is_star
		return ErrorEnum::UNKNOWN_ERROR unless self.save
		return self.is_star
	end

	def set_community(show_in_community)
		self.show_in_community = show_in_community
		return self.save
	end

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
	def serialize
		survey_obj = Hash.new
		survey_obj["_id"] = self._id.to_s
		survey_obj["user_id"] = self.user_id.to_s
		survey_obj["created_at"] = self.created_at
		survey_obj["pages"] = Marshal.load(Marshal.dump(self.pages))
		META_ATTR_NAME_ARY.each do |attr_name|
			method_obj = self.method("#{attr_name}".to_sym)
			survey_obj[attr_name] = method_obj.call()
		end
		survey_obj["quota"] = Marshal.load(Marshal.dump(self.quota))
		survey_obj["filters"] = Marshal.load(Marshal.dump(self.filters))
		survey_obj["logic_control"] = Marshal.load(Marshal.dump(self.logic_control))
		survey_obj["access_control_setting"] = Marshal.load(Marshal.dump(self.access_control_setting))
		survey_obj["style_setting"] = Marshal.load(Marshal.dump(self.style_setting))
		survey_obj["publish_status"] = self.publish_status
		survey_obj["status"] = self.status
		survey_obj["quality_control_questions_type"] = self.quality_control_questions_type
		survey_obj["quality_control_questions_ids"] = self.quality_control_questions_ids
		survey_obj["deadline"] = self.deadline
		survey_obj["is_star"] = self.is_star
		return survey_obj
	end


	def allocate(system_user_type, user_id, allocate)
		user = User.find_by_id(user_id)
		return ErrorEnum::USER_NOT_EXIST if user.nil?
		case system_user_type
		when "answer_auditor"
			return ErrorEnum::USER_NOT_EXIST if !(user.is_answer_auditor || user.is_admin)
			self.answer_auditors << user if allocate
			self.answer_auditors.delete(user) if !allocate
		when "entry_clerk"
			return ErrorEnum::USER_NOT_EXIST if !(user.is_entry_clerk || user.is_admin)
			self.entry_clerks << user if allocate
			self.entry_clerks.delete(user) if !allocate
		when "interviewer"
			return ErrorEnum::USER_NOT_EXIST if !(user.is_interviewer || user.is_admin)
			self.interviewers << user if allocate
			self.interviewers.delete(user) if !allocate
		else
			return ErrorEnum::SYSTEM_USER_TYPE_ERROR
		end
		return self.save
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

	def self.find_by_ids(survey_id_list)
		return Survey.all.in(_id: survey_id_list)
	end
	
	def self.find_new_by_user(user)
		return user.surveys.where(:new_survey => true)[0]
	end

	def self.list(status, publish_status, tags)
		puts "status:: #{status}"
		puts "publish_status:: #{publish_status}, type: #{publish_status.class}"
		survey_list = []
		case status
		when "all"
			surveys = Survey.all_but_new
		when "deleted"
			surveys = Survey.deleted_but_new
		when "normal"
			surveys = Survey.normal_but_new
		else
			surveys = []
		end

		surveys.each do |survey|
			if tags.nil? ||  tags.empty? || survey.has_one_tag_of(tags)
				if publish_status.nil? ||publish_status == '' || survey.publish_status == publish_status.to_i
					survey_list << survey
				end
			end
		end
		# sort by created_at
		return survey_list.sort{|v1,v2| v2.created_at <=> v1.created_at}
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

	def update_access_control_setting(access_control_setting_obj)
		access_control_setting_obj["times_for_one_computer"] = access_control_setting_obj["times_for_one_computer"].to_i
		access_control_setting_obj["password_control"]["password_type"] = 
			access_control_setting_obj["password_control"]["password_type"].to_i
		self.access_control_setting = access_control_setting_obj
		self.save
		return true
	end

	def show_access_control_setting
		return self.access_control_setting
	end

	def is_pageup_allowed
		return self.style_setting["allow_pageup"]
	end

	def is_random_quality_control_questions
		return self.quality_control_questions_type == 2
	end

	def show_quality_control
		return {"quality_control_questions_type" => self.quality_control_questions_type,
				"quality_control_questions_ids" => self.quality_control_questions_ids}
	end

	def update_quality_control(quality_control_questions_type, quality_control_questions_ids)
		return ErrorEnum::WRONG_QUALITY_CONTROL_QUESTIONS_TYPE if ![0, 1, 2].include?(quality_control_questions_type)
		quality_control_questions_ids.each do |qc_id|
			return ErrorEnum::QUALITY_CONTROL_QUESTION_NOT_EXIST if QualityControlQuestion.find_by_id(qc_id).nil?
		end
		self.quality_control_questions_type = quality_control_questions_type
		self.quality_control_questions_ids = quality_control_questions_ids
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
	#* title of the new survey
	#
	#*retval*:
	#* the new survey instance: if successfully cloned
	#* ErrorEnum ::UNAUTHORIZED : if the user is unauthorized to do that
	def clone_survey(operator, title = nil)
		# clone the meta data of the survey
		new_instance = self.clone
		new_instance.title = title || new_instance.title

		# some information that cannot be cloned
		new_instance.status = 0
		new_instance.publish_status = (operator.is_admin || operator.is_super_admin) ? QuillCommon::PublishStatusEnum::PUBLISHED : QuillCommon::PublishStatusEnum::CLOSED
		new_instance.user_attr_survey = false

		new_instance.is_star = false
		new_instance.point = 0
		new_instance.spread_point = 0
		new_instance.spreadable = false
		new_instance.reward = 0
		new_instance.show_in_community = false
		lottery = new_instance.lottery
		lottery.surveys.delete(new_instance) if !lottery.nil?
		new_instance.interviewers.each do |i| new_instance.interviewers.delete(i) end
		new_instance.entry_clerks.each do |e| new_instance.entry_clerks.delete(e) end
		new_instance.answer_auditors.each do |a| new_instance.answer_auditors.delete(a) end

		# the mapping of question ids
		question_id_mapping = {}

		# clone all questions
		new_instance.pages.each do |page|
			page["questions"].each_with_index do |question_id, question_index|
				question = Question.find_by_id(question_id)
				return ErrorEnum::QUESTION_NOT_EXIST if question == nil
				cloned_question = question.clone
				page["questions"][question_index] = cloned_question._id.to_s
				question_id_mapping[question_id] = cloned_question._id.to_s
			end
		end

		# clone quota rules
		new_instance.quota["rules"].each do |quota_rule|
			quota_rule["conditions"].each do |condition|
				if condition["condition_type"] == 1
					condition["name"] = question_id_mapping[condition["name"]]
				end
			end
		end
		new_instance.refresh_quota_stats

		# clone quota rules
		new_instance.filters.each do |filter|
			filter["conditions"].each do |condition|
				if condition["condition_type"] == 1
					condition["name"] = question_id_mapping[condition["name"]]
				end
			end
		end

		# clone logic control rules
		new_instance.logic_control.each do |logic_control_rule|
			logic_control_rule["conditions"].each do |condition|
				condition["question_id"] = question_id_mapping[condition["question_id"]]
			end
			if [1, 2].include?(logic_control_rule["rule_type"])
				logic_control_rule["result"].each_with_index do |question_id, index|
					logic_control_rule["result"][index] = question_id_mapping[question_id]
				end
			elsif [3, 4].include?(logic_control_rule["rule_type"])
				logic_control_rule["result"].each do |result_ele|
					result_ele["question_id"] = question_id_mapping[result_ele["question_id"]]
				end
			elsif [5, 6].include?(logic_control_rule["rule_type"])
				logic_control_rule["result"]["question_id_1"] = question_id_mapping[logic_control_rule["result"]["question_id_1"]]
				logic_control_rule["result"]["question_id_2"] = question_id_mapping[logic_control_rule["result"]["question_id_2"]]
			end
		end

		new_instance.save

		return new_instance
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
		return ErrorEnum::UNAUTHORIZED if self.user._id != operator._id && !operator.is_admin && !operator.is_super_admin
		return ErrorEnum::WRONG_PUBLISH_STATUS if QuillCommon::PublishStatusEnum::CLOSED != self.publish_status
		before_publish_status = self.publish_status
		if operator.is_admin || operator.is_super_admin
			self.update_attributes(:publish_status => QuillCommon::PublishStatusEnum::PUBLISHED)
			publish_status_history = PublishStatusHistory.create_new(operator._id, before_publish_status, QuillCommon::PublishStatusEnum::PUBLISHED, message)
		else
			self.update_attributes(:publish_status => QuillCommon::PublishStatusEnum::UNDER_REVIEW)
			publish_status_history = PublishStatusHistory.create_new(operator._id, before_publish_status, QuillCommon::PublishStatusEnum::UNDER_REVIEW, message)
		end
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
		return ErrorEnum::WRONG_PUBLISH_STATUS if self.publish_status != QuillCommon::PublishStatusEnum::UNDER_REVIEW
		before_publish_status = self.publish_status
		self.update_attributes(:publish_status => QuillCommon::PublishStatusEnum::CLOSED)
		publish_status_history = PublishStatusHistory.create_new(operator._id, before_publish_status, QuillCommon::PublishStatusEnum::CLOSED, message)
		self.publish_status_historys << publish_status_history
		# message
		message ||={}
		operator.create_message(
			message[:title] || '管理人员-拒绝问卷审核', 
			message[:content] || '问卷有问题噢！', 
			[] << self.user.id.to_s)

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
		return ErrorEnum::WRONG_PUBLISH_STATUS if self.publish_status != QuillCommon::PublishStatusEnum::UNDER_REVIEW
		before_publish_status = self.publish_status
		self.update_attributes(:publish_status => QuillCommon::PublishStatusEnum::PUBLISHED)
		self.deadline = Time.now.to_i + 30.days.to_i if self.deadline.blank?
		self.save
		publish_status_history = PublishStatusHistory.create_new(operator._id, before_publish_status, QuillCommon::PublishStatusEnum::PUBLISHED, message)
		self.publish_status_historys << publish_status_history
		# message
		message ||={}
		operator.create_message(
			message[:title] || '管理人员-通过问卷审核', 
			message[:content] || '问卷通过审核，己发布!', 
			[] << self.user.id.to_s)
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
		return ErrorEnum::WRONG_PUBLISH_STATUS if ![QuillCommon::PublishStatusEnum::PUBLISHED, QuillCommon::PublishStatusEnum::UNDER_REVIEW].include?(self.publish_status)
		before_publish_status = self.publish_status
		self.update_attributes(:publish_status => QuillCommon::PublishStatusEnum::CLOSED)
		publish_status_history = PublishStatusHistory.create_new(operator._id, before_publish_status, QuillCommon::PublishStatusEnum::CLOSED, message)
		self.publish_status_historys << publish_status_history
		return true
	end

	#*description*: clear the cached survey object corresponding to current instance, usually called when the survey is updated, either its meta data, or questions and constrains
	#
	#*params*:
	def clear_survey_object
		Cache.write(self._id, nil)
		return true
	end

	def set_new
		# self.new_survey = true
		return true
	end


	def update_new
		if self.alt_new_survey
			self.new_survey = false
		else
			self.alt_new_survey = true
		end
		return true
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
		if current_page == nil
			# if the page cannot be found, append a new page in the last and insert the question into that page
			self.pages << {"name" => "", "questions" => []}
			page_index = self.pages.length - 1
			question_id = "-1"
			current_page = self.pages[page_index]
		end
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
		# do not create new question, just insert the template question id into the pages
		# question = Question.create_template_question(template_question)
		current_page["questions"].insert(question_index+1, template_question_id)
		self.save
		return true
	end

	def convert_template_question_to_normal_question(question_id)
		return ErrorEnum::QUESTION_NOT_EXIST if !self.has_question(question_id)
		question = TemplateQuestion.find_by_id(question_id)
		return ErrorEnum::QUESTION_NOT_EXIST if question.nil?
		# quality control question in a survey cannot be updated
		normal_question = question.convert_template_question_to_normal_question
		# replace the template question with the normal question
		self.pages.each do |page|
			page["questions"].each_with_index do |q_id, index|
				if q_id == question_id
					page["questions"][index] = normal_question._id.to_s
				end
			end
		end
		self.save
		return normal_question
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
		question = Question.find_by_id(question_id)
		return ErrorEnum::QUESTION_NOT_EXIST if !self.has_question(question_id) || question.nil?
		# quality control question in a survey cannot be updated
		question_inst = question.clone
		retval = question.update_question(question_obj)
		# the logic control rules need to be adjusted
		adjust_logic_control_quota_filter('question_update', question_id)
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
		# if the to_page does not exist, create a new page at the end of the survey
		if to_page == nil
			self.pages << {"name" => "", "questions" => []}
			to_page = self.pages[-1]
			question_id_2 = "-1"
		end
		if question_id_2.to_s == "-1"
			question_index = -1
		else
			question_index = to_page["questions"].index(question_id_2)
			return ErrorEnum::QUESTION_NOT_EXIST if question_index == nil
		end
		question_index_to_be_delete = from_page["questions"].index(question_id_1)
		from_page["questions"][question_index_to_be_delete] = ""
		to_page["questions"].insert(question_index+1, question_id_1)
		from_page["questions"].delete("")
		# the logic control rules need to be adjusted
		adjust_logic_control_quota_filter('question_move', question_id_1)
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
		question = BasicQuestion.find_by_id(question_id)
		return ErrorEnum::QUESTION_NOT_EXIST if question.nil?
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
		# logic control rules need to be adjusted
		adjust_logic_control_quota_filter('question_delete', question_id)
		question.clear_question_object
		question.destroy if question.type_of(Question)
		return true
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
		new_page = {"name" => page_name, "questions" => []}
		self.pages.insert(page_index+1, new_page)
		self.save
		return new_page
	end

	# split page before question_id
	def split_page(page_index, question_id, page_name_1, page_name_2)
		current_page = self.pages[page_index]
		return ErrorEnum::OVERFLOW if current_page.nil?
		if question_id.to_s == "-1"
			question_index = current_page["questions"].length
		else
			question_index = -1
			current_page["questions"].each_with_index do |q_id, q_index|
				if q_id == question_id
					question_index = q_index
					break
				end
			end
			return ErrorEnum::QUESTION_NOT_EXIST if question_index == -1
		end
		if question_index == 0
			new_page_1 = {"name" => page_name_1, "questions" => []}
		else
			new_page_1 = {"name" => page_name_1,
						"questions" => current_page["questions"][0..question_index-1]}
		end
		new_page_2 = {"name" => page_name_2,
						"questions" => current_page["questions"][question_index..current_page["questions"].length-1]}
		self.pages.delete_at(page_index)
		self.pages.insert(page_index, new_page_2)
		self.pages.insert(page_index, new_page_1)
		self.save
		return [new_page_1, new_page_2]
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

	def delete_page(page_index)
		current_page = self.pages[page_index]
		return ErrorEnum::OVERFLOW if current_page.nil?
		return delete_page!(page_index)
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
	def delete_page!(page_index)
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
		end
		(page_index_2 - page_index_1).times do
			self.pages.delete_at(page_index_1+1)
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
		if user_attr_survey.to_s == "true"
			Survey.where(:user_attr_survey => true).each do |s|
				s.user_attr_survey = false
				s.save
			end
		end
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
				q = TemplateQuestion.find_by_id(q_id)
				next if q.nil?
				questions << q
			end
		end
		return {survey._id.to_s => questions}
	end

	# return all the surveys that are published and are active
	# it is needed to send emails and invite volunteers for these surveys
	def self.get_published_active_surveys
		return surveys = Survey.normal.in_community.where(:publish_status => QuillCommon::PublishStatusEnum::PUBLISHED)
	end

	def check_password_for_preview(username, password, current_user)
		case self.access_control_setting["password_control"]["password_type"]
		when -1
			return true
		when 0
			if self.access_control_setting["password_control"]["single_password"] == password
				return true
			else
				return ErrorEnum::WRONG_SURVEY_PASSWORD
			end
		when 1
			list = self.access_control_setting["password_control"]["password_list"]
			password_element = list.select { |ele| ele["content"] == password }[0]
		when 2
			list = self.access_control_setting["password_control"]["username_password_list"]
			password_element = list.select { |ele| ele["content"] == [username, password] }[0]
		end
		if password_element.nil?
			return ErrorEnum::WRONG_SURVEY_PASSWORD
		else
			return true
		end
	end

	def has_prize
		# need to fill this method
		reward > 0 ? true : false
	end

	def check_password(username, password, current_user)
		case self.access_control_setting["password_control"]["password_type"]
		when -1
			return true
		when 0
			if self.access_control_setting["password_control"]["single_password"] == password
				return true
			else
				return ErrorEnum::WRONG_SURVEY_PASSWORD
			end
		when 1
			list = self.access_control_setting["password_control"]["password_list"]
			password_element = list.select { |ele| ele["content"] == password }[0]
		when 2
			list = self.access_control_setting["password_control"]["username_password_list"]
			password_element = list.select { |ele| ele["content"] == [username, password] }[0]
		end
		if password_element.nil?
			return ErrorEnum::WRONG_SURVEY_PASSWORD
		elsif password_element["used"] == false
			password_element["used"] = true
			self.save
			return true
		else
			return ErrorEnum::SURVEY_PASSWORD_USED
		end
	end

	def check_progress(detail)
		progress = {}

		progress["screened_answer_number"] = self.answers.not_preview.screened.length
		progress["finished_answer_number"] = self.answers.not_preview.finished.length
		progress["answer_number"] = progress["screened_answer_number"] + progress["finished_answer_number"]

		return progress if detail.to_s == "true"

		start_publish_time_ary = self.publish_status_historys.start_publish_time
		end_publish_time_ary = self.publish_status_historys.end_publish_time

		if start_publish_time_ary.blank?
			progress["duration"] = 0
		elsif end_publish_time_ary.blank?
			progress["duration"] = Time.now.to_i - start_publish_time_ary[0]
		else
			progress["duration"] = end_publish_time_ary[0] - start_publish_time_ary[0]
		end

		self.refresh_quota_stats
		progress["quota"] = self.quota
		progress["filters"] = self.filters
		return progress
	end

	def show_quota
		return Marshal.load(Marshal.dump(self.quota))
	end

	def get_user_ids_answered
		return self.answers.map {|a| a.user_id.to_s}	
	end

	def estimate_answer_time
		answer_time = 0.0
		self.pages.each do |page|
			page["questions"].each do |q_id|
				q = Question.find_by_id(q_id)
				answer_time = answer_time + q.estimate_answer_time if !q.nil?
			end
		end
		return answer_time
	end

	def show_quota_rule(quota_rule_index)
		quota = Quota.new(self.quota)
		return quota.show_rule(quota_rule_index)
	end

	def add_quota_rule(quota_rule)
		quota = Quota.new(self.quota)
		retval = quota.add_rule(quota_rule, self)
		self.refresh_quota_stats if retval
		return self.quota["rules"][-1]
	end

	def update_quota_rule(quota_rule_index, quota_rule)
		quota = Quota.new(self.quota)
		retval = quota.update_rule(quota_rule_index, quota_rule, self)
		self.refresh_quota_stats if retval
		return self.quota["rules"][quota_rule_index]
	end

	def delete_quota_rule(quota_rule_index)
		quota = Quota.new(self.quota)
		retval = quota.delete_rule(quota_rule_index, self)
		self.refresh_quota_stats if retval
		return retval
	end

	def refresh_quota_stats
		# only make statisics from the answers that are not preview answers
		finished_answers = self.answers.not_preview.finished
		unreviewed_answers = self.answers.not_preview.unreviewed

		# initialze the quota stats
		self.quota["finished_count"] = 0
		self.quota["submitted_count"] = 0
		self.quota["rules"].each do |rule|
			rule["finished_count"] = 0
			rule["submitted_count"] = 0
		end

		# make stats for the finished answers
		finished_answers.each do |answer|
			self.quota["finished_count"] ||= 0
			self.quota["finished_count"] += 1
			self.quota["submitted_count"] ||= 0
			self.quota["submitted_count"] += 1
			self.quota["rules"].each do |rule|
				if answer.satisfy_conditions(rule["conditions"])
					rule["finished_count"] += 1
					rule["submitted_count"] += 1
				end
			end
		end

		# make stats for the unreviewed answers
		unreviewed_answers.each do |answer|
			self.quota["submitted_count"] += 1
			self.quota["rules"].each do |rule|
				if answer.satisfy_conditions(rule["conditions"])
					rule["submitted_count"] += 1
				end
			end
		end

		# calculate whether quota is satisfied
		quota["rules"].each do |rule|
			self.quota["quota_satisfied"] &&= rule["finished_count"] >= rule["amount"]
		end
		self.save
		return quota
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

	def show_logic_control_with_question_objects
		logic_control = Marshal.load(Marshal.dump(self.logic_control))
		logic_control.each do |rule|
			conditions = rule["conditions"]
			conditions.each do |c|
				c["question"] = BasicQuestion.find_by_id(c["question_id"])
			end
			result = rule["result"]
			if [1,2].include?(rule["rule_type"])
				result.each_with_index do |q_id, index|
					result[index] = BasicQuestion.find_by_id(q_id)
				end
			elsif [3,4].include?(rule["rule_type"])
				result.each do |r|
					r["question"] = BasicQuestion.find_by_id(r["question_id"])
				end
			elsif [5,6].include?(rule["rule_type"])
				result.each do |r|
					r["question_1"] = BasicQuestion.find_by_id(r["question_id_1"])
					r["question_2"] = BasicQuestion.find_by_id(r["question_id_2"])
				end
			end
		end
		return logic_control
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

	def list_filters
		return Marshal.load(Marshal.dump(self.filters))
	end

	def show_filter(filter_index)
		filters = Filters.new(self.filters)
		return filters.show_filter(filter_index)
	end

	def add_filter(filter)
		filters = Filters.new(self.filters)
		return filters.add_filter(filter, self)
	end

	def update_filter(filter_index, filter)
		filters = Filters.new(self.filters)
		return filters.update_filter(filter_index, filter, self)
	end

	def delete_filter(filter_index)
		filters = Filters.new(self.filters)
		return filters.delete_filter(filter_index, self)
	end

	def analysis(filter_index, include_screened_answer)
		return ErrorEnum::FILTER_NOT_EXIST if filter_index >= self.filters.length
		task_id = TaskClient.create_task({ task_type: "result",
											host: "localhost",
											port: Rails.application.config.service_port,
											params: { result_type: "analysis",
														survey_id: self._id,
														filter_index: filter_index,
														include_screened_answer: include_screened_answer} })
		return task_id
	end

	def report(filter_index, include_screened_answer, report_mockup_id, report_style, report_type)
		return ErrorEnum::FILTER_NOT_EXIST if filter_index >= self.filters.length
		# if report_mockup_id is nil, export all single questions analysis with default charts
		if !report_mockup_id.blank?
			report_mockup = self.report_mockups.find_by_id(report_mockup_id)
			return ErrorEnum::REPORT_MOCKUP_NOT_EXIST if report_mockup.nil?
		end
		return ErrorEnum::WRONG_REPORT_TYPE if !%w[word ppt pdf].include?(report_type)
		task_id = TaskClient.create_task({ task_type: "result",
											host: "localhost",
											port: Rails.application.config.service_port,
											params: { result_type: "report",
														survey_id: self._id,
														filter_index: filter_index,
														include_screened_answer: include_screened_answer,
														report_mockup_id: report_mockup_id,
														report_style: report_style,
														report_type: report_type } })
		return task_id
	end

	def get_answers(filter_index, include_screened_answer, task_id = nil)
		# answers = include_screened_answer ? self.answers.not_preview.finished_and_screened : self.answers.not_preview.finished
		answers = self.answers.not_preview.finished_and_screened
		if filter_index == -1
			TaskClient.set_progress(task_id, "find_answers_progress", 1.0) if !task_id.nil?
			#set_status({"find_answers_progress" => 1})
			tot_answer_number = answers.length
			answers = include_screened_answer ? answers : answers.finished
			return [answers, tot_answer_number, self.answers.not_preview.screened.length]
		end
		filter_conditions = self.filters[filter_index]["conditions"]
		filtered_answers = []
		tot_answer_number = 0
		not_screened_answer_number = 0
		answers_length = answers.length
		answers.each_with_index do |a, index|
			next if !a.satisfy_conditions(filter_conditions)
			tot_answer_number += 1
			next if !include_screened_answer && a.is_screened
			not_screened_answer_number += 1
			filtered_answers << a
			#set_status({"find_answers_progress" => (index + 1) * 1.0 / answers_length})
			TaskClient.set_progress(task_id, "find_answers_progress", (index + 1).to_f / answers_length) if !task_id.nil?
		end
		return [filtered_answers, tot_answer_number, tot_answer_number - not_screened_answer_number]
	end

	def create_report_mockup(report_mockup)
		result = ReportMockup.check_and_create_new(self, report_mockup)
		return result
	end

	def show_report_mockup(report_mockup_id)
		report_mockup = self.report_mockups.find_by_id(report_mockup_id)
		return ErrorEnum::REPORT_MOCKUP_NOT_EXIST if report_mockup.nil?
		return report_mockup
	end

	def list_report_mockups
		return self.report_mockups
	end

	def delete_report_mockup(report_mockup_id)
		report_mockup = self.report_mockups.find_by_id(report_mockup_id)
		if !report_mockup.nil?
			report_mockup.destroy
			return true
		else
			return ErrorEnum::REPORT_MOCKUP_NOT_EXIST
		end
	end

	def update_report_mockup(report_mockup_id, report_mockup_obj)
		report_mockup = self.report_mockups.find_by_id(report_mockup_id)
		return ErrorEnum::REPORT_MOCKUP_NOT_EXIST if report_mockup.nil?
		return report_mockup.update_report_mockup(report_mockup_obj)
	end

	class Filters
		CONDITION_TYPE = (0..4).to_a
		def initialize(filters)
			@filters = Marshal.load(Marshal.dump(filters))
		end

		def show_filter(filter_index)
			return ErrorEnum::FILTER_NOT_EXIST if @filters[filter_index].nil?
			return @filters[filter_index]
		end

		def add_filter(filter, survey)
			# check errors
			filter["conditions"].each do |condition|
				condition["condition_type"] = condition["condition_type"].to_i
				return ErrorEnum::WRONG_FILTER_CONDITION_TYPE if !CONDITION_TYPE.include?(condition["condition_type"])
			end
			# add the rule
			@filters << filter
			survey.filters = self.serialize
			survey.save
			return survey.filters
		end

		def delete_filter(filter_index, survey)
			# check errors
			return ErrorEnum::FILTER_NOT_EXIST if @filters[filter_index].nil?
			# delete the rule
			@filters.delete_at(filter_index)
			survey.filters = self.serialize
			return survey.save
		end

		def update_filter(filter_index, filter, survey)
			# check errors
			return ErrorEnum::FILTER_NOT_EXIST if @filters[filter_index].nil?
			filter["conditions"].each do |condition|
				condition["condition_type"] = condition["condition_type"].to_i
				return ErrorEnum::WRONG_FILTER_CONDITION_TYPE if !CONDITION_TYPE.include?(condition["condition_type"].to_i)
			end
			# update the rule
			@filters[filter_index] = filter
			survey.filters = self.serialize
			survey.save
			return survey.filters
		end

		def serialize
			filters_object = @filters
			return filters_object
		end
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
			rule["finished_count"] = 0
			rule["submitted_count"] = 0
			return ErrorEnum::WRONG_QUOTA_RULE_AMOUNT if rule["amount"].to_i <= 0
			rule["conditions"].each do |condition|
				condition["condition_type"] = condition["condition_type"].to_i
				return ErrorEnum::WRONG_QUOTA_RULE_CONDITION_TYPE if !CONDITION_TYPE.include?(condition["condition_type"])
			end
			# add the rule
			@rules << rule
			survey.quota = self.serialize
			survey.save
			return @rules.length - 1
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
			return rule_index
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

	def adjust_logic_control_quota_filter(type, question_id)
		# first adjust the logic control
		question = BasicQuestion.find_by_id(question_id)
		rules = self.logic_control
		rules.each_with_index do |rule, rule_index|
			case type
			when 'question_update'
				item_ids = question.issue["items"].map { |i| i["id"] }
				row_ids = question.issue["rows"].map { |i| i["id"] } if !question.issue["rows"].nil?
				# first handle conditions
				if question.question_type == 0
					# only choice questions can be conditions for logic control
					if (0..4).to_a.include?(rule["rule_type"])
						rule["conditions"].each do |c|
							next if c["question_id"] != question_id
							# the condition is about the question updated
							# remove the items that do not exist
							c["answer"].delete_if { |item_id| !item_ids.include?(item_id) }
						end
						# if all the items for a condition is removed, remove this condition
						rule["conditions"].delete_if { |c| c["answer"].blank? }
						# if all the conditions for a rule is removed, remove this rule
						if rule["conditions"].blank?
							rules.delete_at(rule_index)
							next
						end
					end
				end
				# then handle result
				if [3,4].to_a.include?(rule["rule_type"])
					rule["result"].each do |r|
						next if r["question_id"] != question_id
						# the result is about the question updated
						# remove the items that do not exist
						r["items"].delete_if { |item_id| !item_ids.include?(item_id) }
						# remove the rows that do not exist
						r["sub_questions"].delete_if { |row_id| !row_ids.include?(row_id) }
					end
					# if all the items for a result is removed, remove this result
					rule["result"].delete_if { |r| r["items"].blank? && r["sub_questions"].blank? }
					# if all the results for a rule is removed, remove this rule
					rules.delete_at(rule_index) if rule["result"].blank?
				elsif [5,6].to_a.include?(rule["rule_type"])
					if rule["result"]["question_id_1"] == question_id
						rule["result"]["items"].delete_if { |i| !item_ids.include?(i[0]) }
					elsif rule["result"]["question_id_2"] == question_id
						rule["result"]["items"].delete_if { |i| !item_ids.include?(i[1]) }
					end
					# if all the results for a rule is removed, remove this rule
					rules.delete_at(rule_index) if rule["result"]["items"].blank?
				end
			when 'question_move'
				question_ids = self.all_questions_id
				if [1,2].to_a.include?(rule["rule_type"])
					# a show/hide questions rule
					conditions_question_ids = rule["conditions"].map { |c| c["question_id"] }
					result_question_ids = rule["result"]
					if conditions_question_ids.include?(question_id)
						# the conditions include the question to be moved
						result_question_ids.each do |result_question_id|
							if !question_ids.before(question_id, result_question_id)
								rule["conditions"].delete_if { |c| c["question_id"] == question_id }
							end
						end
					end
					if result_question_ids.include?(question_id)
						# the results include the question to be moved
						conditions_question_ids.each do |condition_question_id|
							if !question_ids.before(condition_question_id, question_id)
								rule["result"].delete(question_id)
							end
						end
					end
					rules.delete_at(rule_index) if rule["conditions"].blank? || rule["result"].blank?
				elsif [3,4].to_a.include?(rule["rule_type"])
					# a show/hide items rule
					conditions_question_ids = rule["conditions"].map { |c| c["question_id"] }
					result_question_ids = rule["result"].map { |r| r["question_id"] }
					if conditions_question_ids.include?(question_id)
						# the conditions include the question to be moved
						result_question_ids.each do |result_question_id|
							if !question_ids.before(question_id, result_question_id)
								rule["conditions"].delete_if { |c| c["question_id"] == question_id }
							end
						end
					end
					if result_question_ids.include?(question_id)
						# the results include the question to be moved
						conditions_question_ids.each do |condition_question_id|
							if !question_ids.before(condition_question_id, question_id)
								rule["result"].delete_if { |r| r["question_id"] == question_id }
							end
						end
					end
					rules.delete_at(rule_index) if rule["conditions"].blank? || rule["result"].blank?
				elsif [5,6].to_a.include?(rule["rule_type"])
					rules.delete_at(rule_index) if question_ids.before(rule["result"]["question_id_1"], rule["result"]["question_id_2"])
				end
			when 'question_delete'
				if ![5,6].include?(rule["rule_type"])
					# not a corresponding items rule
					# adjust the conditions part
					rule["conditions"].delete_if { |c| c["question_id"] == question_id }
					# adjust the result part
					if [1, 2].include?(rule["rule_type"])
						rule["result"].delete(question_id)
					elsif [3, 4].include?(rule["rule_type"])
						rule["result"].delete_if { |r| r["question_id"] == question_id }
					end
					# check whether this logic control rule can be removed
					if rule["conditions"].blank?
						# no conditions, can be removed
						rules.delete_at(rule_index)
					elsif (1..4).to_a.include?(rule["rule_type"]) && rule["result"].blank?
						# no results for the show/hide questions/items, can be removed
						rules.delete_at(rule_index)
					end
				else
					# a corresponding items rule
					if rule["result"]["question_id_1"] == question_id || rule["result"]["question_id_2"] == question_id
						rules.delete_at(rule_index)
					end
				end
			end
		end
		self.save
		# then adjust the quota
		if question.question_type == 0
			# only choice questions can be conditions of quotas
			rules = self.quota["rules"]
			rules.each_with_index do |rule, rule_index|
				next if rule["conditions"].blank?
				case type
				when 'question_update'
					item_ids = question.issue["items"].map { |i| i["id"] }
					row_ids = question.issue["items"].map { |i| i["id"] }
					rule["conditions"].each do |c|
						next if c["condition_type"] != 1 || c["name"] != question_id
						# this condition is about the updated question
						c["value"].delete_if { |item_id| !item_ids.include?(item_id) }
					end
					rule["conditions"].delete_if { |c| c["value"].blank? }
					rules.delete_at(rule_index) if rule["conditions"].blank?
					self.refresh_quota_stats
				when 'question_delete'
					rule["conditions"].delete_if { |c| c["condition_type"] == 1 && c["name"] == question_id }
					rules.delete_at(rule_index) if rule["conditions"].blank?
					self.refresh_quota_stats
				end
			end 
			self.save
		end
		# then adjust the filters
		if question.question_type == 0
			# only choice questions can be conditions of filters
			rules = self.filters
			rules.each_with_index do |rule, rule_index|
				case type
				when 'question_update'
					question = Question.find_by_id(question_id)
					item_ids = question.issue["items"].map { |i| i["id"] }
					row_ids = question.issue["items"].map { |i| i["id"] }
					rule["conditions"].each do |c|
						next if c["condition_type"] != 1 || c["name"] != question_id
						# this condition is about the updated question
						c["value"].delete_if { |item_id| !item_ids.include?(item_id) }
					end
					rule["conditions"].delete_if { |c| c["value"].blank? }
					rules.delete_at(rule_index) if rule["conditions"].blank?
				when 'question_delete'
					rule["conditions"].delete_if { |c| c["condition_type"] == 1 && c["name"] == question_id }
					rules.delete_at(rule_index) if rule["conditions"].blank?
				end
			end 
			self.save
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

	def post_reward_to(user, options = {})
		options[:user] = user
		RewardLog.create(options).created_at ? true : false
	end

	def set_spread(spread_point, spreadable)
		self.spread_point = spread_point
		self.spreadable = spreadable
		return self.save
	end

	def self.list_surveys_in_community(reward, only_spreadable, user)
		surveys = Survey.in_community
		surveys = surveys.where(:spreadable => true) if only_spreadable
		surveys = surveys.where(:reward => reward)
		surveys = surveys.order_by(:publish_status, :desc).order_by(:created_at, :desc)
		return surveys.map { |s| {"survey" => s.serialize_in_short, "answer_status" => s.answer_status(user)} }
	end

	def self.list_answered_surveys(user)
		answers = user.answers.not_preview
		surveys_with_answer_status = []
		answers.each do |a|
			next if a.survey.nil?
			surveys_with_answer_status << {"survey" => a.survey.serialize_in_short, "answer_status" => a.status}
		end
		return surveys_with_answer_status
	end

	def self.list_spreaded_surveys(user)
		answers = Answer.finished.where(:is_preview => false, :introducer_id => user._id)
		surveys_with_spread_number = []
		user.survey_spreads.each do |ss|
			survey = ss.survey
			surveys_with_spread_number << {"survey" => survey.serialize_in_short, "answer_status" => survey.answer_status(user), "spread_number" => ss.times}
		end
		return surveys_with_spread_number
	end

	def self.search_title(query)
		surveys = Survey.where(title: Regexp.new(query.to_s)).desc(:created_at)
		return surveys.map { |s| s.serialize_in_list_page }
	end

	def serialize_in_list_page
		survey_obj = Hash.new
		survey_obj["_id"] = self._id.to_s
		survey_obj["title"] = self.title.to_s
		survey_obj["subtitle"] = self.subtitle.to_s
		survey_obj["created_at"] = self.created_at
		survey_obj["updated_at"] = self.updated_at
		survey_obj["reward"] = self.reward
		survey_obj["publish_status"] = self.publish_status
		survey_obj["status"] = self.status
		survey_obj["is_star"] = self.is_star
		survey_obj['screened_answer_number']=self.answers.not_preview.screened.length
		survey_obj['finished_answer_number']=self.answers.not_preview.finished.length
		return survey_obj
	end

	def serialize_in_short
		survey_obj = Hash.new
		survey_obj["_id"] = self._id.to_s
		survey_obj["title"] = self.title.to_s
		survey_obj["subtitle"] = self.subtitle.to_s
		survey_obj["created_at"] = self.created_at.to_i
		survey_obj["reward_info"] = self.reward_info
		survey_obj["publish_status"] = self.publish_status
		return survey_obj
	end

	def answer_status(user)
		return nil if user.nil?
		answer = Answer.where(:survey_id => self._id.to_s, :user_id => user._id.to_s, :is_preview => false)[0]
		return nil if answer.nil?
		return answer.status
	end

	def reward_info
		return {"reward_type" => self.reward,
				"point" => self.point,
				"lottery_id" => self.lottery_id,
				"spreadable" => self.spreadable,
				"spread_point" => self.spread_point}
	end

	def remaining_quota_amount
		number = 0
		self.quota["rules"].each_with_index do |rule, rule_index|
			number += [rule["amount"] - rule["submitted_count"], 0].max
		end
		return number
	end

	def last_update_time
		last_update_time = self.updated_at.to_i
		self.all_questions_id.each do |q_id|
			q = BasicQuestion.find_by_id(q_id)
			next if q.nil?
			last_update_time = [last_update_time, q.updated_at.to_i].max
		end
		return last_update_time
	end
end
