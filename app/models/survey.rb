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
	field :subtitle, :type => String, default: ""
	field :welcome, :type => String, default: ""
	field :closing, :type => String, default: "调查问卷结束语"
	field :header, :type => String, default: ""
	field :footer, :type => String, default: ""
	field :description, :type => String, default: "调查问卷描述"
	# can be 1 (closed), 2 (published), 4 (deleted)
	field :status, :type => Integer, default: 1
	field :pages, :type => Array, default: [{"name" => "", "questions" => []}]
	field :quota, :type => Hash, default: {"rules" => ["conditions" => [], "amount" => 100, "finished_count" => 0, "submitted_count" => 0], "is_exclusive" => true, "quota_satisfied" => false, "finished_count" => 0, "submitted_count" => 0 }
	field :filters, :type => Array, default: []
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
	field :publish_result, :type => Boolean, :default => false
	field :delta, :type => Boolean, :default => true
	field :point, :type => Integer, :default => 0
	# whether this survey can be introduced to another person
	field :spreadable, :type => Boolean, :default => false
	# reward for introducing others
	field :spread_point, :type => Integer, default: 0
	field :quillme_promotable, :type => Boolean, default: false
	field :quillme_hot, :type => Boolean, :default => false #是否为热点小调查(quillme用)
	field :recommend_position, :type => Integer, :default => nil  #推荐位
	field :email_promotable, :type => Boolean, default: false
	field :sms_promotable, :type => Boolean, default: false
	field :broswer_extension_promotable, :type => Boolean, default: false
	field :weibo_promotable, :type => Boolean, default: false

	field :quillme_hot, :type => Boolean, :default => false #是否为热点小调查(quillme用)
	field :quillme_promote_info, :type => Hash, :default => {
		"reward_scheme_id" => ""
	}

	# 0 免费, 1 表示话费，2表示支付宝转账，4表示优币，8表示抽奖，16表示发放集分宝
	field :quillme_promote_reward_type,:type => Integer, default: nil

	field :email_promote_info, :type => Hash, default: {
		"email_amount" => 0,
		"promote_to_undefined_sample" => false,
		"promote_email_count" => 0,
		"reward_scheme_id" => ""
	}
	field :sms_promote_info, :type => Hash, default: {
		"sms_amount" => 0,
		"promote_to_undefined_sample" => false,
		"promote_sms_count" => 0,		
		"reward_scheme_id" => ""
	}
	field :broswer_extension_promote_info, :type => Hash, default: {
		"login_sample_promote_only" => false,
		"filter" => [[{"key_word" => [""], "url" => ""}]],
		"reward_scheme_id" => ""
	}
	field :weibo_promote_info, :type => Hash, default: {
		"text" => "",
		"image" => "",
		"video" => "",
		"audio" => "",
		"reward_scheme_id" => ""
	}
	field :sample_attributes_for_promote, :type => Array, default: []


	# reward: 0: nothing, 1: priPze, 2: point
	# field_remove :reward, :type => Integer, :default => 0
	# field_remove :show_in_community, :type => Boolean, default: false
	# whether this survey can be promoted by emails or other ways
	# field_remove :promotable, :type => Boolean, :default => false
	# field_remove :promote_email_number, :type => Integer, :default => 0
	# whether the answers of the survey need to be reviewed
	# field_remove :answer_need_review, :type => Boolean, :default => false

	has_many :answers
	has_many :reward_schemes
	has_many :email_histories
	has_many :survey_spreads
	has_many :export_results
	has_many :analysis_results
	has_many :report_results
	has_many :report_mockups
	has_many :interviewer_tasks
	has_many :agent_tasks
	has_and_belongs_to_many :answer_auditors, class_name: "User", inverse_of: :answer_auditor_allocated_surveys
	has_and_belongs_to_many :entry_clerks, class_name: "User", inverse_of: :entry_clerk_allocated_surveys
	has_and_belongs_to_many :tags do
		def has_tag?(content)
			@target.each do |tag|
				return true if tag.content == content
			end
			return false
		end
	end
	belongs_to :lottery
	belongs_to :user, class_name: "User", inverse_of: :surveys


	scope :published, lambda { where(:status  => 2) }
	scope :normal, lambda { where(:status.gt => -1) }
	scope :deleted, lambda { where(:status => -1) }
	scope :stars, where(:status.gt => -1, :is_star => true)
	scope :in_community, lambda { where(:show_in_community => true) }
	scope :is_promotable, lambda { where(:promotable => true) }
	
 
	scope :status, lambda {|st| where(:status => st)}
	scope :reward_type,lambda {|rt| where(:quillme_promote_reward_type.in => rt)}
	scope :opend, lambda { where(:status => 2)}
	scope :closed, lambda { where(:status => 1)}
	scope :quillme_promote, lambda { where(:quillme_promotable => true)}
	scope :quillme_hot, lambda {where(:quillme_hot => true)}
	scope :not_quillme_hot, lambda {where(:quillme_hot => false)}


	index({ status: 1, show_in_community: 1, title: 1 }, { background: true } )
	index({ show_in_community: 1, title: 1 }, { background: true } )
	index({ title: 1 }, { background: true } )
	index({ status: 1, show_in_community: 1, title: 1 }, { background: true } )
	index({ status: 1, title: 1 }, { background: true } )
	index({ status: 1, title: 1 }, { background: true } )
	index({ status: 1, reward: 1}, { background: true } )
	index({ status: 1 }, { background: true } )
	index({ status: 1, is_star: 1 }, { background: true } )
	index({ status: 1, promotable: 1}, { background: true } )
	index({ spreadable: 1 }, { background: true } )

	before_save :clear_survey_object
	before_update :clear_survey_object
	before_destroy :clear_survey_object

	META_ATTR_NAME_ARY = %w[title subtitle welcome closing header footer description]
	CLOSED = 1
	PUBLISHED = 2
	DELETED = 4

	public

	def self.can_lottery?(survey_id,answer_id)
		survey = Survey.find_by_id(survey_id)
		return ErrorEnum::SURVEY_NOT_EXIST unless survey.present?
		return ErrorEnum::SURVEY_CLOSED if survey.status ==  CLOSED
		return ErrorEnum::SUEVEY_DELETED if survey.status == DELETED
		answer = Answer.find_by_id(answer_id)

		return ErrorEnum::ANSWER_NOT_EXIST unless answer.present?
		

	end

	def self.get_recommends(status=2,reward_type=nil)
		status = 2 unless status.present?
		reward_type = nil unless reward_type.present?
		if reward_type.present?
		reward_type = reward_type.split(',')
		end
		if reward_type.present?
		surveys = Survey.quillme_promote.not_quillme_hot.status(status).reward_type(reward_type).desc(:created_at)		
		else
		surveys = Survey.quillme_promote.not_quillme_hot.status(status).desc(:created_at)		
		end	
		return surveys
	end

	def answered(user)
		answer  = self.answers.where(:user_id => user.id).first if user.present?
		return [answer.try(:status),answer.try(:reject_type)]   	
	end

	def reward_type_info
		rs = RewardScheme.where(:_id => self.quillme_promote_info['reward_scheme_id']).first
		info = rs.rewards[0] if rs
		return info
	end

	def excute_sample_data(user)
		self['answer_count'] = self.answers.count
		self['time'] = self.estimate_answer_time
		self['answer_status'] = self.answered(user)[0]
		self['answer_reject_type'] = self.answered(user)[1]
		self['reward_type_info'] = self.reward_type_info
		return self
	end


    def self.get_reward_type_count(status=2)
    	status = 2 unless status.present?
    	reward_types = Survey.quillme_promote.not_quillme_hot.status(status).map{|s| s.quillme_promote_reward_type}
    	reward_data = {}
    	reward_types.each do |rt|
    		reward_data[rt] = Survey.where(:quillme_promote_reward_type => rt).count
    	end
    	return reward_data
    end

	#----------------------------------------------
	#
	#     find_by_*
	#
	#++++++++++++++++++++++++++++++++++++++++++++++

	def self.find_by_id(survey_id)
		return Survey.where(:_id => survey_id).first
	end

	def self.find_by_ids(survey_id_list)
		return Survey.all.in(_id: survey_id_list)
	end

	def self.find_by_fields(h_fields)
		return Survey.all.desc(:created_at) if h_fields.blank?
		return Survey.where(h_fields).desc(:created_at)
	end

	def append_user_fields(arr_fields)
		if !self.blank?
			arr_fields.each do |field|
				self[field] = self.user.send(field)
			end
		end
		return self
	end

	def get_all_promote_settings
		return self.serialize_in_promote_setting
	end

	def update_quillme_promote_reward_type
		reward_scheme = RewardScheme.find_by_id(self.quillme_promote_info["reward_scheme_id"])
		self.update_attributes({"quillme_promote_reward_type" => 0}) and return if reward_scheme.nil?
		self.update_attributes({"quillme_promote_reward_type" => 0}) and return if reward_scheme.rewards.blank?
		self.update_attributes({"quillme_promote_reward_type" => reward_scheme.rewards[0]["type"].to_i})
	end

	#----------------------------------------------
	#
	#     tags manupulation
	#
	#++++++++++++++++++++++++++++++++++++++++++++++

	def has_one_tag_of(tags)
		survey_tags = self.tags.map {|tag_inst| tag_inst.content}
		return !(survey_tags & tags).empty?
	end

	def add_tag(tag)
		return ErrorEnum::TAG_EXIST if self.tags.has_tag?(tag)
		self.tags << Tag.get_or_create_new(tag)
		return true
	end

	def remove_tag(tag)
		return ErrorEnum::TAG_NOT_EXIST if !self.tags.has_tag?(tag)
		tag_inst = Tag.find_by_content(tag)
		self.tags.delete(tag_inst)
		tag_inst.destroy if tag_inst.surveys.length == 0
		return true
	end

	#----------------------------------------------
	#
	#     set and get basic properties and attributes of the survey
	#
	#++++++++++++++++++++++++++++++++++++++++++++++

	def save_meta_data(survey_obj)
		# this is an existing survey
		if !survey_obj.nil?
			META_ATTR_NAME_ARY.each do |attr_name|
				if !survey_obj[attr_name].nil?
					method_obj = self.method("#{attr_name}=".to_sym)
					method_obj.call(survey_obj[attr_name])
				end
			end
			self.save
		end
		return self
	end

	def update_deadline(time)
		time = time.to_i
		return ErrorEnum::SURVEY_DEADLINE_ERROR if time <= Time.now.to_i && time != -1
		self.deadline = time == -1 ? nil : time
		self.save
		#create delay job
		if !self.deadline.nil?
			Survey.delay_until(self.deadline, :retry => false, :timeout => 10).deadline_arrived(self._id.to_s)
		end
		return true
	end

	def update_star(is_star)
		self.is_star = is_star
		self.save
		return self.is_star
	end

	def set_community(show_in_community)
		self.show_in_community = show_in_community
		return self.save
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

=begin
	def reward_info
		return {"reward_type" => self.reward,
				"point" => self.point,
				"lottery_id" => self.lottery_id,
				"lottery_title" => self.lottery.try(:title),
				"spreadable" => self.spreadable,
				"spread_point" => self.spread_point}
	end
=end

	def has_prize
		reward > 0 ? true : false
	end

	def set_spread(spread_point, spreadable)
		self.spread_point = spread_point
		self.spreadable = spreadable
		return self.save
	end

	def self.deadline_arrived(survey_id)
		s = Survey.find_by_id(survey_id)
		return if s.nil?
		return if s.deadline.nil?
		if Time.now.to_i - s.deadline < 20 && s.deadline - Time.now.to_i < 20
			# close the survey and refresh the quota
			s.update_attributes(status: CLOSED) if survey.status == PUBLISHED
			s.refresh_quota_stats
		end
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

	#----------------------------------------------
	#
	#     clone survey
	#
	#++++++++++++++++++++++++++++++++++++++++++++++

	def clone_survey(operator, title = nil)
		# clone the meta data of the survey
		new_instance = self.clone
		new_instance.user = operator
		new_instance.title = title || new_instance.title
		new_instance.created_at = Time.now

		# some information that cannot be cloned
		new_instance.status = 0
		new_instance.status = (operator.is_admin || operator.is_super_admin) ? PUBLISHED : CLOSED

		new_instance.is_star = false
		new_instance.point = 0
		new_instance.spread_point = 0
		new_instance.spreadable = false
		new_instance.reward = 0
		new_instance.show_in_community = false
		lottery = new_instance.lottery
		lottery.surveys.delete(new_instance) if !lottery.nil?
		new_instance.entry_clerks.each do |a| new_instance.entry_clerks.delete(a) end
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

	#----------------------------------------------
	#
	#     manipulate on status of the survey
	#
	#++++++++++++++++++++++++++++++++++++++++++++++

	def delete
		return self.update_attributes(:status => -1)
	end

	def recover
		return self.update_attributes(:status => 0)
	end

	def clear
		return ErrorEnum::SURVEY_NOT_EXIST if self.status != -1
		self.tags.each do |tag|
			tag.destroy if tag.surveys.length == 1
		end
		return self.destroy
	end

	#----------------------------------------------
	#
	#     manipulate on publish status of the survey
	#
	#++++++++++++++++++++++++++++++++++++++++++++++

	def close(operator)
		return ErrorEnum::UNAUTHORIZED if self.user._id != operator._id && !operator.is_admin && !operator.is_survey_auditor
		return ErrorEnum::WRONG_STATUS if self.status != PUBLISHED
		self.update_attributes(:status => CLOSED)
		return true
	end

	def publish(operator)
		return ErrorEnum::UNAUTHORIZED if self.user._id != operator._id && !operator.is_admin && !operator.is_survey_auditor
		return ErrorEnum::WRONG_STATUS if self.status != CLOSED
		self.update_attributes(:status => PUBLISHED)
		return true
	end

	#----------------------------------------------
	#
	#     manipulate on questions
	#
	#++++++++++++++++++++++++++++++++++++++++++++++

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

	def get_question_inst(question_id)
		return ErrorEnum::QUESTION_NOT_EXIST if !self.has_question(question_id)
		question = Question.find_by_id(question_id)
		return ErrorEnum::QUESTION_NOT_EXIST if question.nil?
		return question
	end

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

	def all_questions(include_prg = true)
		q = []
		pages.each do |page|
			q += page["questions"]
		end
		ques = []
		q.collect do |i|
			que = Question.find(i)
			ques << que if (que.question_type != QuestionTypeEnum:: PARAGRAPH || include_prg)
		end
		return ques
	end

	def all_questions_id(include_prg = true)
		q = []
		pages.each do |page|
			q += page["questions"]
		end
		ques = []
		if include_prg
			return q
		else
			q.collect do |i|
				que = Question.find(i)
				ques << i if (que.question_type != QuestionTypeEnum:: PARAGRAPH || include_prg)
			end
			return ques
		end
	end

	def all_questions_type(include_prg = true)
		q = []
		self.all_questions.each do |que|
			if que.question_type != QuestionTypeEnum:: PARAGRAPH || include_prg
				q << Kernel.const_get(QuestionTypeEnum::QUESTION_TYPE_HASH["#{que.question_type}"] + "Io").new(que)
			end
		end
		q
	end

	def has_question(question_id)
		self.pages.each do |page|
			return true if page["questions"].include?(question_id)
		end
		return false
	end

	def adjust_logic_control_quota_filter(type, question_id)
		# first adjust the logic control
		question = BasicQuestion.find_by_id(question_id)
		rules = self.logic_control
		rules.each_with_index do |rule, rule_index|
			case type
			when 'question_update'
				next if question.issue["items"].nil? && question.issue["rows"].nil?
				item_ids = (question.issue["items"].try(:map) { |i| i["id"] }) || []
				if question.issue["other_item"] && question.issue["other_item"]["has_other_item"] == true
					item_ids << question.issue["other_item"]["id"]
				end
				row_ids = (question.issue["rows"].try(:map) { |i| i["id"] }) || []
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
			need_refresh_quota = false
			rules.each_with_index do |rule, rule_index|
				next if rule["conditions"].blank?
				case type
				when 'question_update'
					item_ids = question.issue["items"].map { |i| i["id"] }
					if question.issue["other_item"] && question.issue["other_item"]["has_other_item"] == true
						item_ids << question.issue["other_item"]["id"]
					end
					row_ids = question.issue["items"].map { |i| i["id"] }
					need_refresh_quota = false
					rule["conditions"].each do |c|
						next if c["condition_type"] != 1 || c["name"] != question_id
						# this condition is about the updated question
						l1 = c["value"].length
						c["value"].delete_if { |item_id| !item_ids.include?(item_id) }
						need_refresh_quota = true if l1 != c["value"].length
					end
					rule["conditions"].delete_if { |c| c["value"].blank? }
					rules.delete_at(rule_index) if rule["conditions"].blank?
				when 'question_delete'
					l1 = rule["conditions"].length
					rule["conditions"].delete_if { |c| c["condition_type"] == 1 && c["name"] == question_id }
					if l1 != rule["conditions"].length
						rules.delete_at(rule_index) if rule["conditions"].blank?
						need_refresh_quota = true
					end
				end
			end
			self.refresh_quota_stats if need_refresh_quota
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
					if question.issue["other_item"] && question.issue["other_item"]["has_other_item"] == true
						item_ids << question.issue["other_item"]["id"]
					end
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

	#----------------------------------------------
	#
	#     manipulate on pages
	#
	#++++++++++++++++++++++++++++++++++++++++++++++

	def create_page(page_index, page_name)
		return ErrorEnum::OVERFLOW if page_index < -1 or page_index > self.pages.length - 1
		new_page = {"name" => page_name, "questions" => []}
		self.pages.insert(page_index+1, new_page)
		self.save
		return new_page
	end

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

	def show_page(page_index)
		current_page = self.pages[page_index]
		return ErrorEnum::OVERFLOW if current_page.nil?
		page_object = {name: current_page["name"], questions: []}
		current_page["questions"].each do |question_id|
			temp = Question.get_question_object(question_id)
			temp["index"] = self.all_questions_id.index(question_id)
			page_object[:questions] << temp
		end
		return page_object
	end

	def update_page(page_index, page_name)
		current_page = self.pages[page_index]
		return ErrorEnum::OVERFLOW if current_page.nil?
		current_page["name"] = page_name
		return self.save
	end

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

	def move_page(page_index_1, page_index_2)
		current_page = self.pages[page_index_1]
		return ErrorEnum::OVERFLOW if current_page == nil
		return ErrorEnum::OVERFLOW if page_index_2 < -1 or page_index_2 > self.pages.length - 1
		self.pages.insert(page_index_2+1, current_page)
		self.pages.delete_at(page_index_1)
		return self.save
	end

	#----------------------------------------------
	#
	#     for answering process
	#
	#++++++++++++++++++++++++++++++++++++++++++++++
	def check_password(username, password, is_preview)
		case self.access_control_setting["password_control"]["password_type"]
		when -1
			return true
		when 0
			return self.access_control_setting["password_control"]["single_password"] == password
		when 1
			list = self.access_control_setting["password_control"]["password_list"]
			password_element = list.select { |ele| ele["content"] == password }[0]
		when 2
			list = self.access_control_setting["password_control"]["username_password_list"]
			password_element = list.select { |ele| ele["content"] == [username, password] }[0]
		end
		return false if password_element.nil?
		return true if is_preview
		if password_element["used"] == false
			password_element["used"] = true
			self.save
			return true
		else
			return false
		end
	end

	def get_user_ids_answered
		return self.answers.not_preview.map {|a| a.user_id.to_s}
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

	def estimate_price
		# todo: estimate price
		return 10
	end

	#----------------------------------------------
	#
	#     manipulate on quotas
	#
	#++++++++++++++++++++++++++++++++++++++++++++++

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
			self.quota["finished_count"] += 1
			self.quota["submitted_count"] += 1
			self.quota["rules"].each do |rule|
				if answer.satisfy_conditions(rule["conditions"], false)
					rule["finished_count"] += 1
					rule["submitted_count"] += 1
				end
			end
		end

		# make stats for the unreviewed answers
		unreviewed_answers.each do |answer|
			self.quota["submitted_count"] += 1
			self.quota["rules"].each do |rule|
				if answer.satisfy_conditions(rule["conditions"], false)
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

	def show_quota
		return Marshal.load(Marshal.dump(self.quota))
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

	#----------------------------------------------
	#
	#     manipulate on logic control
	#
	#++++++++++++++++++++++++++++++++++++++++++++++

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

	#----------------------------------------------
	#
	#     manipulate on filters
	#
	#++++++++++++++++++++++++++++++++++++++++++++++

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

	#----------------------------------------------
	#
	#     result related
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

	def spss_header
		headers =[]
		self.all_questions(false).each_with_index do |e, i|
			headers += e.spss_header("q#{i+1}")
		end
		headers
	end

	def excel_header
		headers =[]
		self.all_questions(false).each_with_index do |e, i|
			headers += e.excel_header("q#{i+1}")
		end
		headers
	end

	def csv_header(options = {})
		if options[:with] == "import_id"
			headers = ["import_id"]
		else
			headers = []
		end
		self.all_questions(false).each_with_index do |e, i|
			headers += e.csv_header("q#{i+1}")
		end
		headers
	end

	def to_spss(analysis_task_id)
		task_id = Task.create(:task_type => "to_spss")._id.to_s
		ToSpssWorker.perform_async(self._id.to_s, analysis_task_id, task_id)
		return task_id
	end

	def to_excel(analysis_task_id)
		task_id = Task.create(:task_type => "to_excel")._id.to_s
		ToExcelWorker.perform_async(self._id.to_s, analysis_task_id, task_id)
		return task_id
	end

	def formated_answers(answers, result_key, task_id)
		answer_c = []
		formated_error = []
		qindex = 0
		q = self.all_questions_type(false)
		p "========= 准备完毕 ========="
		answer_length = answers.length
		last_time = Time.now.to_i
		answers.each_with_index do |answer, index|
			line_answer = []
			begin
				all_questions_id(false).each_with_index do |question, index|
					qindex = index
					line_answer += q[index].answer_content(answer.answer_content[question], "q#{index + 1}")
				end
			rescue Exception => test
				formated_error << [test, index + 1, qindex + 1, q[index + 1].class]
			else
				answer_c << line_answer
			end
			if Time.now.to_i != last_time
				Task.set_progress(task_id, "data_conversion_progress", (index+1).to_f / answer_length)
				last_time = Time.now.to_i
			end
		end
		Task.set_progress(task_id, "data_conversion_progress", 1.0)
		answer_c
	end

	def analysis(filter_index, include_screened_answer)
		return ErrorEnum::FILTER_NOT_EXIST if filter_index >= self.filters.length
		task_id = Task.create(:task_type => "analysis")._id.to_s
		AnalysisWorker.perform_async(self._id.to_s, filter_index, include_screened_answer, task_id)
		return task_id
	end

	def report(analysis_task_id, report_mockup_id, report_style, report_type)
		# return ErrorEnum::FILTER_NOT_EXIST if filter_index >= self.filters.length
		# if report_mockup_id is nil, export all single questions analysis with default charts
		if !report_mockup_id.blank?
			report_mockup = self.report_mockups.find_by_id(report_mockup_id)
			return ErrorEnum::REPORT_MOCKUP_NOT_EXIST if report_mockup.nil?
		end
		return ErrorEnum::WRONG_REPORT_TYPE if !%w[word ppt pdf].include?(report_type)
		return ErrorEnum::WRONG_REPORT_STYLE if !(0..6).to_a.include?(report_style.to_i)
		task_id = Task.create(:task_type => "report")._id.to_s
		ReportWorker.perform_async(self._id.to_s,
			analysis_task_id,
			report_mockup_id,
			report_type,
			report_style,
			task_id)
		return task_id
	end

	def get_answers(filter_index, include_screened_answer, task_id = nil)
		# answers = include_screened_answer ? self.answers.not_preview.finished_and_screened : self.answers.not_preview.finished
		answers = self.answers.not_preview.finished_and_screened
		ongoing_answer_number = self.answers.not_preview.ongoing.length
		wait_for_review_answer_number = self.answers.not_preview.wait_for_review.length
		if filter_index == -1
			Task.set_progress(task_id, "find_answers_progress", 1.0) if !task_id.nil?
			#set_status({"find_answers_progress" => 1})
			tot_answer_number = answers.length
			answers = include_screened_answer ? answers : answers.finished
			return [answers, tot_answer_number, self.answers.not_preview.screened.length, ongoing_answer_number, wait_for_review_answer_number]
		end
		filter_conditions = self.filters[filter_index]["conditions"]
		filtered_answers = []
		tot_answer_number = 0
		not_screened_answer_number = 0
		answers_length = answers.length
		last_time  =Time.now.to_i
		answers.each_with_index do |a, index|
			next if !a.satisfy_conditions(filter_conditions, false)
			tot_answer_number += 1
			not_screened_answer_number += 1 if !a.is_screened
			next if !include_screened_answer && a.is_screened
			filtered_answers << a
			if Time.now.to_i != last_time
				Task.set_progress(task_id, "find_answers_progress", (index + 1).to_f / answers_length) if !task_id.nil?
				last_time = Time.now.to_i
			end
		end
		Task.set_progress(task_id, "find_answers_progress", 1.0) if !task_id.nil?
		return [filtered_answers, tot_answer_number, tot_answer_number - not_screened_answer_number, ongoing_answer_number, wait_for_review_answer_number]
	end

	#----------------------------------------------
	#
	#     report mockup related
	#
	#++++++++++++++++++++++++++++++++++++++++++++++

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

	def self.list(status)
		status_ary = Tool.convert_int_to_base_arr(status)
		return Survey.where(:status.in => status_ary).desc(:created_at).map { |s| s.serialize_in_list_page }
	end

	def self.search_title(query)
		surveys = Survey.where(title: Regexp.new(query.to_s)).desc(:created_at)
		return surveys.map { |s| s.serialize_in_list_page }
	end

	def answer_status(user)
		return nil if user.nil?
		answer = Answer.where(:survey_id => self._id.to_s, :user_id => user._id.to_s, :is_preview => false)[0]
		return nil if answer.nil?
		return answer.status
	end

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
		survey_obj["status"] = self.status
		survey_obj["quality_control_questions_type"] = self.quality_control_questions_type
		survey_obj["quality_control_questions_ids"] = self.quality_control_questions_ids
		survey_obj["deadline"] = self.deadline
		survey_obj["is_star"] = self.is_star
		return survey_obj
	end

	def serialize_in_list_page
		survey_obj = {}
		survey_obj["_id"] = self._id.to_s
		survey_obj["title"] = self.title.to_s
		survey_obj["subtitle"] = self.subtitle.to_s
		survey_obj["created_at"] = self.created_at
		survey_obj["updated_at"] = self.updated_at
		survey_obj["status"] = self.status
		survey_obj["is_star"] = self.is_star
		survey_obj['screened_answer_number']=self.answers.not_preview.screened.length
		survey_obj['finished_answer_number']=self.answers.not_preview.finished.length
		return survey_obj
	end

	def info_for_sample
		survey_obj = {}
		survey_obj["_id"] = self._id.to_s
		survey_obj["title"] = self.title.to_s
		survey_obj["subtitle"] = self.subtitle.to_s
		survey_obj["created_at"] = self.created_at.to_i
		survey_obj["status"] = self.status
		survey_obj["spreadable"] = self.spreadable
		survey_obj["spread_point"] = self.spread_point
		survey_obj["quillme_promote_reward_type"] = self.quillme_promote_reward_type.to_i
		return survey_obj
	end

	def info_for_browser
		survey_obj = {}
		survey_obj["_id"] = self._id.to_s
		survey_obj["title"] = self.title.to_s
		survey_obj["created_at"] = self.created_at.to_i
		survey_obj["broswer_extension_promote_info"] = self.broswer_extension_promote_info
		survey_obj["rewards"] = self.rewards
		return survey_obj
	end

	def serialize_for(arr_fields)
		survey_obj = {"id" => self.id.to_s}
		arr_fields.each do |field|
			if [:created_at, :updated_at].include?(field)
				survey_obj[field] = self.send(field).to_i
			else
				survey_obj[field] = self.send(field)
			end
		end
		return survey_obj
	end

	def serialize_in_promote_setting
		survey_obj = Hash.new
		survey_obj["quillme_promotable"] = self.quillme_promotable
		survey_obj["quillme_promote_info"] = Marshal.load(Marshal.dump(self.quillme_promote_info))
		survey_obj["email_promotable"] = self.email_promotable
		survey_obj["email_promote_info"] = Marshal.load(Marshal.dump(self.email_promote_info))
		survey_obj["sms_promotable"] = self.sms_promotable
		survey_obj["sms_promote_info"] = Marshal.load(Marshal.dump(self.sms_promote_info))
		survey_obj["broswer_extension_promotable"] = self.broswer_extension_promotable
		survey_obj["broswer_extension_promote_info"] = Marshal.load(Marshal.dump(self.broswer_extension_promote_info))
		survey_obj["weibo_promotable"] = self.weibo_promotable
		survey_obj["weibo_promote_info"] = Marshal.load(Marshal.dump(self.weibo_promote_info))
		return survey_obj
	end

	def info_for_interviewer
		survey_obj = {}
		survey_obj["_id"] = self._id.to_s
		survey_obj["created_at"] = self.created_at
		survey_obj["pages"] = Marshal.load(Marshal.dump(self.pages))
		META_ATTR_NAME_ARY.each do |attr_name|
			method_obj = self.method("#{attr_name}".to_sym)
			survey_obj[attr_name] = method_obj.call()
		end
		survey_obj["logic_control"] = Marshal.load(Marshal.dump(self.logic_control))
		survey_obj["access_control_setting"] = Marshal.load(Marshal.dump(self.access_control_setting))
		survey_obj["style_setting"] = Marshal.load(Marshal.dump(self.style_setting))
		info = {"survey" => survey_obj}
		self.all_questions_id.each do |qid|
			info = info.merge({qid => BasicQuestion.find_by_id(qid)})
		end
		return info
	end

	def info_for_agent
		survey_obj = {}
		survey_obj["_id"] = self._id.to_s
		survey_obj["title"] = self.title
		return survey_obj
	end

	def answer_import(csv_str)
		q = []
		batch = []
		import_error = []
		imported_answer = nil
		updated_count = 0
		header_prefix = 0
		all_questions.each do |a|
			q << Kernel.const_get(QuestionTypeEnum::QUESTION_TYPE_HASH["#{a.question_type}"] + "Io").new(a)
		end
		CSV.parse(csv_str, :headers => true) do |row|
			return false if row.headers != self.csv_header(:with => "import_id")
			if self.answers.where(:import_id => row["import_id"]).length > 0
				imported_answer = self.answers.where(:import_id => row["import_id"].to_s).first
			end
			row = row.to_hash
			line_answer = {}
			quota_qustions_count = 0 # quota_qustions.size
			begin
				q.each_with_index do |e, i|
					#q = Kernel.const_get(QuestionTypeEnum::QUESTION_TYPE_HASH["#{e.question_type}"] + "Io").new(e)
					header_prefix = "q#{i + 1}"
					line_answer.merge! e.answer_import(row, header_prefix)
				end
			rescue Exception => test
				import_error << {row:row, message:"第#{header_prefix}题:#{test.to_s}"}
			else
				if imported_answer
					imported_answer.assign_attributes(:answer_content => line_answer)
					imported_answer.save
					updated_count += 1
					imported_answer = nil
				else
					batch << {:answer_content => line_answer,
										:import_id => row["import_id"],
										:channel => -1,
										:survey_id => self._id,
										:status => 3,
										:random_quality_control_answer_content => {},
										:random_quality_control_locations => {},
										:logic_control_result => {},
										:username => "",
										:password => "",
										:region => -1,
										:ip_address => "",
										:audit_message => "",
										:is_scanned => false,
										:is_preview => false,
										:finished_at => Time.now.to_i,
										:created_at => Time.now,
										:updated_at => Time.now}
				end
			end
		end
		# return false if batch.empty?
		Answer.collection.insert(batch) unless batch.empty?
		self.refresh_quota_stats
		self.save
		{
			:insert_count => batch.length,
			:updated_count => updated_count,
			:error => import_error
		}
	end

	def post_reward_to(user, options = {})
		options[:user] = user
		RewardLog.create(options).created_at ? true : false
	end

	def allocate_answer_auditors(answer_auditor_ids, allocate)
		retval = {}
		answer_auditor_ids.each do |id|
		answer_auditor = User.find_by_id(id)
		retval[id] = USER_NOT_EXIST and next if user.blank? or user.is_answer_auditor?
		if allocate
			self.answer_auditors << answer_auditor
		else
			self.answer_auditors.delete(answer_auditor)
		end
		self.save
		end
		retval = (retval.blank? ? true : retval)
		return retval
	end

	def clear_survey_object
		Cache.write(self._id, nil)
		return true
	end

	def set_quillme_hot
		s = Survey.where(:quillme_hot => true).first
		if !s.nil?
			s.quillme_hot = false
			s.save
		end
		self.quillme_hot = true
		return self.save
	end

	def info_for_admin
		survey_obj = {}
		survey_obj["id"] = self._id.to_s
		survey_obj["created_at"] = self.created_at.to_i
		survey_obj["pages"] = Marshal.load(Marshal.dump(self.pages))
		META_ATTR_NAME_ARY.each do |attr_name|
			method_obj = self.method("#{attr_name}".to_sym)
			survey_obj[attr_name] = method_obj.call()
		end
		survey_obj["logic_control"] = Marshal.load(Marshal.dump(self.logic_control))
		survey_obj["access_control_setting"] = Marshal.load(Marshal.dump(self.access_control_setting))
		survey_obj["style_setting"] = Marshal.load(Marshal.dump(self.style_setting))
		survey_obj["answer_time"] = self.estimate_answer_time
		survey_obj["price"] = self.estimate_price
		user_obj = {}
		user_obj["id"] = self.user._id.to_s
		user_obj["email"] = self.user.email
		user_obj["mobile"] = self.user.mobile
		questions = {}
		self.all_questions_id.each do |qid|
			questions[qid] = BasicQuestion.find_by_id(qid)
		end
		info = {"survey" => survey_obj,
			"user" => user_obj,
			"questions" => questions}
		return info
	end

	def add_sample_attribute_for_promote(sample_attribute)
		s = SampleAttribute.normal.find_by_id(sample_attribute["sample_attribute_id"])
		return ErrorEnum::SAMPLE_ATTRIBUTE_NOT_EXIST if s.nil?
		self.sample_attributes_for_promote << sample_attribute
		return self.save
	end

	def remove_sample_attribute_for_promote(index)
		self.sample_attributes_for_promote.delete(index)
		return self.save
	end

	def create_default_reward_scheme
		r = RewardScheme.create(:name => "默认奖励方案", :rewards => [], :need_review => false)
		self.reward_schemes << r
	end
end
