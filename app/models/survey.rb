# encoding: utf-8
require 'error_enum'
require 'quality_control_type_enum'
require 'publish_status'
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
  extend Mongoid::FindHelper
  include Mongoid::ValidationsExt
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
  # can be 1 (closed), 2 (under review), 4 (paused), 8 (published)
  field :publish_status, :type => Integer, default: 1
  field :user_attr_survey, :type => Boolean, default: false
  field :pages, :type => Array, default: [{"name" => "", "questions" => []}]
  field :quota, :type => Hash, default: {"rules" => ["conditions" => [], "amount" => 100], "is_exclusive" => true}
  field :quota_stats, :type => Hash, default: {"quota_satisfied" => false, "answer_number" => [0]}
  field :filters, :type => Array, default: []
  field :filters_stats, :type => Array, default: []
  field :quota_template_question_page, :type => Array, default: []
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
  field :deadline, :type => Integer
  field :is_star, :type => Boolean, :default => false

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
  has_many :email_histories

  has_many :analyze_results

  scope :all_but_new, lambda { where(:new_survey => false) }
  scope :normal, lambda { where(:status.gt => -1) }
  scope :normal_but_new, lambda { where(:status.gt => -1, :new_survey => false) }
  scope :deleted, lambda { where(:status => -1) }
  scope :deleted_but_new, lambda { where(:status => -1, :new_survey => false) }
  # scope for star
  scope :stars, where(:status.gt => -1, :is_star => true)

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
      q += page[:questions]
    end
    q.collect { |i| Question.find(i) }
  end

  def all_questions_id
    q = []
    pages.each do |page|
      q += page[:questions]
    end
    return q
  end

  def all_questions_type
    q = []
    all_questions.each do |a|
      q << Kernel.const_get(QuestionTypeEnum::QUESTION_TYPE_HASH["#{a.question_type}"] + "Io").new(a)
    end
    q
  end

  def csv_header
    headers = []
    all_questions.each_with_index do |e,i|
      headers += e.csv_header("q#{i+1}")
    end
    headers
  end

  def spss_header
    headers =[]
    all_questions.each_with_index do |e,i|
      headers += e.spss_header("q#{i+1}")
    end
    headers
  end

  def excel_header
    headers =[]
    all_questions.each_with_index do |e,i|
      headers += e.excel_header("q#{i+1}")
    end
    headers
  end

  def get_export_result(filter_index, include_screened_answer)
    filtered_answers = Result.answers(self, filter_index, include_screened_answer)
    answer_ids = filtered_answers.collect { |a| a.id.to_s}.join
    p "===== 获取 Key 成功 ====="
    result_key = Digest::MD5.hexdigest("export_result-#{answer_ids}")
    p "===== 生成 Key 成功 ====="
    result = ExportResult.where(:result_key => result_key).first
    result ||= ExportResult.create(:result_key => result_key,
                                   :survey => self,
                                   :filter_index => filter_index,
                                   :include_screened_answer => include_screened_answer)
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

  def to_spss(filter_index = -1, include_screened_answer = true)
    result = get_export_result(filter_index, include_screened_answer)
    if result.finished
      return "Spss文件的路径:类似于 localhost/result_key.sav"
    else
      Resque.enqueue(Jobs::ToSpssJob, result.result_key)
      #to_spss_r(result)
      #result.to_spss
    end
  end

  # def to_spss_r(result_key)
  def to_spss_r(result)
    filtered_answers = Result.where(:result_key => result.result_key).first.filtered_answers
    result.send_data '/to_spss' do
      {'spss_data' => {"spss_header" => spss_header,
                       "answer_contents" => result.answer_content,
                       "header_name" => csv_header,
                       "result_key" => result.result_key}.to_yaml}
    end
  end
  def to_excel(filter_index = -1, include_screened_answer = true)
    result = get_export_result(filter_index, include_screened_answer)
    if result.finished
      return "Excel文件的路径:类似于 localhost/result_key.xsl"
    else
      # Resque.enqueue(Jobs::ToSpssJob, self.id)
      result.to_excel
    end
  end

  def to_excel_r(result_key)
    filtered_answers = Result.where(:result_key => result_key).first.filtered_answers
    send_data '/to_excel' do
      {'excel_data' => ({"excel_header" => excel_header,
                         "answer_contents" => answer_content,
                         "header_name" => csv_header,
                         "result_key" => result_key}).to_yaml}
    end
  end
  # def to_excel_r(result_key)
  #   filtered_answers = Result.where(:result_key => result_key).first.filtered_answers
  #   data = {'excel_data' => ({"excel_header" => excel_header,
  #                             "answer_contents" => answer_content,
  #                             "header_name" => csv_header,
  #                             "result_key" => result_key}).to_yaml}
  #   send_data '/to_excel', data
  # end
  #--
  # update deadline and create a survey_deadline_job
  #++

  # Example:
  #
  # instance.update_deadline(Time.now+3.days)
  def update_deadline(time)
    time = time.to_i
    return ErrorEnum::SURVEY_DEADLINE_ERROR if time <= Time.now.to_i
    self.deadline = time
    return ErrorEnum::UNKNOWN_ERROR unless self.save
    #create or update job
    Jobs.start(:SurveyDeadlineJob, time, survey_id: self.id)
    return true
  end

  def update_star
    self.is_star = !self.is_star
    return ErrorEnum::UNKNOWN_ERROR unless self.save
    return self.is_star
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
    survey_obj["created_at"] = self.created_at
    survey_obj["pages"] = Marshal.load(Marshal.dump(self.pages))
    META_ATTR_NAME_ARY.each do |attr_name|
      method_obj = self.method("#{attr_name}".to_sym)
      survey_obj[attr_name] = method_obj.call()
    end
    survey_obj["quota"] = Marshal.load(Marshal.dump(self.quota))
    survey_obj["quota_stats"] = Marshal.load(Marshal.dump(self.quota_stats))
    survey_obj["filters"] = Marshal.load(Marshal.dump(self.filters))
    survey_obj["filters_stats"] = Marshal.load(Marshal.dump(self.filters_stats))
    survey_obj["logic_control"] = Marshal.load(Marshal.dump(self.logic_control))
    survey_obj["access_control_setting"] = Marshal.load(Marshal.dump(self.access_control_setting))
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
  # def self.find_by_id(survey_id)
  #   return Survey.where(:_id => survey_id).first
  # end

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

  def set_quality_control_questions_type(quality_control_questions_type)
    return ErrorEnum::WRONG_QUALITY_CONTROL_QUESTIONS_TYPE if [0, 1, 2].include?(quality_control_questions_type)
    self.quality_control_questions_type = quality_control_questions_type
    return self.save
  end

  def is_random_quality_control_questions
    return self.quality_control_questions_type == 2
  end

  def show_quality_control
    quality_control = {"quality_control_questions_type" => self.quality_control_questions_type}
    return quality_control if self.is_random_quality_control_questions

    quality_control_questions = []
    self.pages.each do |page|
      page["questions"].each do |q|
        quality_control_questions << q if q.question_class == 2
      end
    end
    quality_control["quality_control_questions"] = quality_control_questions
    return quality_control
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
  def clone_survey(title = nil)
    # clone the meta data of the survey
    new_instance = self.clone
    new_instance.title = title || new_instance.title

    new_instance.status = 0
    new_instance.publish_status = 1
    new_instance.user_attr_survey = false
    new_instance.quota_stats = {}

    # the mapping of question ids
    question_id_mapping = {}

    # clone all questions
    new_instance.pages.each do |page|
      page["questions"].each_with_index do |question_id, question_index|
        question = Question.find_by_id(question_id)
        return ErrorEnum::QUESTION_NOT_EXIST if question == nil
        cloned_question = question.clone
        page[question_index] = cloned_question._id.to_s
        question_id_mapping[question_id] = cloned_question._id
      end
    end

    # clone template questions
    new_instance.quota_template_question_page.each do |question_id, question_index|
      question = Question.find_by_id(question_id)
      return ErrorEnum::QUESTION_NOT_EXIST if question == nil
      cloned_question = question.clone
      new_instance.quota_template_question_page[question_index] = cloned_question._id.to_s
      question_id_mapping[question_id] = cloned_question._id
    end

    # clone quota rules
    new_instance.quota["rules"].each do |quota_rule|
      quota_rule["conditions"].each do |condition|
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
        logic_control_rule["result"].each do |question_id, index|
          logic_control_rule["result"][index] = question_id_mapping[question_id]
        end
      elsif [3, 4].include?(logic_control_rule["rule_type"])
        logic_control_rule["result"].each do |result_ele|
          result_ele["question_id"] = question_id_mapping[result_ele["question_id"]]
        end
      elsif [5, 6].include?(logic_control_rule["rule_type"])
        logic_control_rule["result"]["question_id_1"] = question_id_mapping[logic_control_rule["result"]["question_id_1"]]
        logic_control_rule["result"]["question_id_2"] = question_id_mapping[logic_control_rule["result"]["question_id_2"]]
      elsif [7, 8].include?(logic_control_rule["rule_type"])
        # for logic control that show/hide pages, it is not needed to replace with new question ids
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

  def update_question(question_id, question_obj)
    if LogicControl.new(self.logic_control).detect_conflict_question_update(question_id)
      return ErrorEnum::LOGIC_CONTROL_CONFLICT_DETECTED
    end
    return update_question!(question_id, question_obj)
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
  def update_question!(question_id, question_obj)
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
    from_page["questions"][question_index_to_be_delete] = ""
    to_page["questions"].insert(question_index+1, question_id_1)
    from_page["questions"].delete("")
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

  def delete_question(question_id)
    if LogicControl.new(self.logic_control).detect_conflict_question_update(question_id)
      return ErrorEnum::LOGIC_CONTROL_CONFLICT_DETECTED
    end
    return delete_question!(question_id)
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
  def delete_question!(question_id)
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
    return ErrorEnum::LOGIC_CONTROL_CONFLICT_DETECTED if LogicControl.new(self.logic_control).detect_conflict_questions_update(current_page["questions"])
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
    return self.list("normal", PublishStatus::PUBLISHED, [])
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
      answer = Answer.find_by_password(username, password)
      return ErrorEnum::ANSWER_NOT_EXIST if answer.nil?
      user = answer.user
      return ErrorEnum::REQUIRE_LOGIN if user.is_registered
      user.answers.delete(answer)
      answer.user = current_user
      answer.save
      return answer
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
    progress["quota_stats"] = self.quota_stats
    self.refresh_filters_stats
    progress["filters"] = self.filters
    progress["filters_stats"] = self.filters_stats
    return progress
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

  def estimate_answer_time
    answer_time = 0
    self.pages.each do |page|
      page["questions"].each do |q_id|
        q = Question.find_by_id(q_id)
        answer_time = answer_time + q.estimate_answer_time if !q.nil?
      end
    end
  end

  def show_quota_rule(quota_rule_index)
    quota = Quota.new(self.quota)
    return quota.show_rule(quota_rule_index)
  end

  def add_quota_rule(quota_rule)
    quota = Quota.new(self.quota)
    retval = quota.add_rule(quota_rule, self)
    self.refresh_quota_stats if retval
    return retval
  end

  def update_quota_rule(quota_rule_index, quota_rule)
    quota = Quota.new(self.quota)
    retval = quota.update_rule(quota_rule_index, quota_rule, self)
    self.refresh_quota_stats if retval
    return retval
  end

  def delete_quota_rule(quota_rule_index)
    quota = Quota.new(self.quota)
    retval = quota.delete_rule(quota_rule_index, self)
    self.refresh_quota_stats if retval
    return retval
  end

  def refresh_filters_stats
    # only make statisics from the answers that are not preview answers
    answers = self.answers.not_preview
    filters_stats = Array.new(self.filters.length, 0)
    answers.each do |answer|
      self.filters.each_with_index do |filter, filter_index|
        conditions = filter["conditions"]
        filters_stats[filter_index] = filters_stats[filter_index] + 1 if answer.satisfy_conditions(conditions)
      end
    end
    self.filters_stats = filters_stats
    self.save
  end

  def refresh_quota_stats
    # only make statisics from the answers that are not preview answers
    answers = self.answers.not_preview
    quota_stats = {"quota_satisfied" => true, "answer_number" => []}
    self.quota["rules"].length.times { quota_stats["answer_number"] << 0 }
    answers.each do |answer|
      self.quota["rules"].each_with_index do |rule, rule_index|
        if answer.satisfy_conditions(rule["conditions"])
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

  def show_analyze_result(filter_index, include_screened_answer)
    return ErrorEnum::FILTER_NOT_EXIST if filter_index >= self.filters.length
    result = self.analyze_results.find_or_create_by_filter_index(self, filter_index, include_screened_answer)
    return result
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
    RULE_TYPE = (0..8).to_a
    def initialize(logic_control)
      @rules = logic_control
    end

    # check whether the updated question is a condition for some logic control rule
    def detect_conflict_question_update(question_id)
      @rules.each do |rule|
        return true if (rule["conditions"].map { |e| e["question_id"] }).include?(question_id)
      end
      return false
    end

    # check whether the updated question is a condition for some logic control rule
    def detect_conflict_questions_update(question_id_ary)
      @rules.each do |rule|
        return true if !((rule["conditions"].map { |e| e["question_id"] }) & question_id_ary).blank?
      end
      return false
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
