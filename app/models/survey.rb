# encoding: utf-8
require 'error_enum'
require 'quill_common'
require 'csv'
Dir[File.dirname(__FILE__) + '/lib/survey_components/*.rb'].each {|file| require file }
class Survey
  
  include Mongoid::Document
  include Mongoid::Timestamps
  include SurveyComponents::SurveyPage
  include SurveyComponents::SurveyLogicControl
  include SurveyComponents::SurveyQuota
  include SurveyComponents::SurveyReportMockup
  include SurveyComponents::SurveyFilter
  include FindTool

  META_ATTR_NAME_ARY = %w[title subtitle welcome closing header footer description]
  CLOSED = 1
  PUBLISHED = 2
  DELETED = 4

  field :title, :type => String, default: "调查问卷主标题"
  field :subtitle, :type => String, default: ""
  field :welcome, :type => String, default: ""
  field :closing, :type => String, default: "调查问卷结束语"
  field :header, :type => String, default: ""
  field :footer, :type => String, default: ""
  field :description, :type => String, default: "调查问卷描述"
  # can be 1 (closed), 2 (published), 4 (deleted)
  field :status, :type => Integer, default: 2
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
  field :max_num_per_ip, :type => Integer, default: 3
  field :deadline, :type => Integer
  field :is_star, :type => Boolean, :default => false
  field :publish_result, :type => Boolean, :default => false
  field :delta, :type => Boolean, :default => true
  # reward for introducing others
  field :spread_point, :type => Integer, default: 0
  field :quillme_promotable, :type => Boolean, default: false
  field :quillme_hot, :type => Boolean, :default => false #是否为热点小调查(quillme用)
  field :recommend_position, :type => Integer, :default => nil  #推荐位
  field :email_promotable, :type => Boolean, default: false
  field :sms_promotable, :type => Boolean, default: false
  field :broswer_extension_promotable, :type => Boolean, default: false
  field :weibo_promotable, :type => Boolean, default: false
  field :quillme_promote_info, :type => Hash, :default => {
    "reward_scheme_id" => ""
  }
  # 0 免费, 1 表示话费，2表示支付宝转账，4表示积分，8表示抽奖，16表示发放集分宝
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
    "filters" => [{"key_words" => [""], "url" => ""}],
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
  field :star, :type => Boolean, default: false


  has_many :answers
  has_many :reward_schemes
  has_many :survey_invitation_histories
  has_many :survey_spreads
  has_many :export_results
  has_many :analysis_results
  has_many :report_results
  has_many :interviewer_tasks
  has_many :agent_tasks
  has_and_belongs_to_many :answer_auditors, class_name: "User", inverse_of: :answer_auditor_allocated_surveys
  belongs_to :user, class_name: "User", inverse_of: :surveys


  scope :status, ->(st) { where(:status.in => Tool.convert_int_to_base_arr(st || (Survey::CLOSED + Survey::PUBLISHED)))}
  scope :title, ->(title) { where(title: Regexp.new(title.to_s)) }
  scope :user, ->(e) {  e.is_admin? ? self.criteria : where(:user_id => e._id) }
  scope :reward_type,->(rt) { where(:quillme_promote_reward_type.in => rt.split(','))}
  scope :opend, -> { where(:status => 2)}
  scope :closed, -> { where(:status => 1)}
  scope :quillme_promote, -> { where(:quillme_promotable => true)}
  scope :quillme_hot, -> {where(:quillme_hot => true)}
  scope :not_quillme_hot, -> {where(:quillme_hot => false)}
  scope :quillme_normal, -> { self.quillme_promote.not_quillme_hot}
  scope :stars, -> {where(:status.in => [CLOSED,PUBLISHED], :is_star => true)}
  scope :published, -> { where(:status  => 2) }
  scope :normal, -> { where(:status.gt => -1) }
  scope :closed, -> { where(:status => 1) }
  scope :deleted, -> { where(:status => 4) }


  index({ title: 1 }, { background: true } )
  index({ status: 1, title: 1 }, { background: true } )
  index({ status: 1, reward: 1}, { background: true } )
  index({ status: 1, is_star: 1 }, { background: true } )

  index({ quillme_promote_reward_type: 1 }, { background: true } )
  index({ quillme_hot: 1 }, { background: true } )
  index({ user_id: 1 }, { background: true } )
  index({ title: 1 }, { background: true } )
  index({ quillme_promotable: 1, quillme_hot: 1,status: 1,created_at: -1}, { background: true } )
  index({ quillme_promotable: 1, quillme_hot: 1,status: 1,quillme_promote_reward_type: 1}, { background: true } )

  public
  # Class Methods
  #######################
  # 问卷吧首页及调研列表页用
  # 参数: opt ={sample:current_user,home_page:true,status:nil,reward_type:nil,answer_status:nil}
  # 参数说明:
  # sample:传递当前登录样本的instance，样本未登录时，可以不传递
  # home_page:表示当前的调用是否为首页调用，如果不是，可以不传递
  # status:表示要查询的surveys的状态，如果传递为nil或者不穿地，则默认会被赋值为2，表示开放中的问卷，如果为1表示关闭的问卷
  # reward_type:表示要查询的某种奖励类型的问卷，传值为nil表示所有奖励类型，如果为字符串类型表示对应类型的问卷,参考值：'1' 或者'1,2,16'等
  # answers_status:nil或者不传值时表示所有状态的问卷，传值参考:'1' 或者'1,2,4,8'等等
  #######################
  def self.get_recommends(opt)
    total_ids = Survey.quillme_normal.map(&:id)
    reward_type = opt[:reward_type].split(',') if opt[:reward_type].present?
    surveys = Survey.quillme_normal.status(opt[:status] || 2).reward_type(opt[:reward_type]).desc(:created_at) if opt[:reward_type].present?
    surveys = Survey.quillme_normal.status(opt[:status] || 2).desc(:created_at) unless opt[:reward_type].present?
    surveys = get_filter_surveys(
      surveys:surveys,total_ids:total_ids,
      answer_status:opt[:answer_status],
      sample:opt[:sample],home_page:opt[:home_page])
  end

  def self.get_filter_surveys(opt)
    if opt[:sample].present?
      if opt[:answer_status].present? && opt[:answer_status].to_i != 0
        survey_ids = opt[:sample].answers.not_preview.special_status(opt[:answer_status]).map(&:survey_id)
      elsif opt[:answer_status].present? && opt[:answer_status].to_i == 0  # 待参与
        survey_ids = opt[:sample].answers.not_preview.map(&:survey_id)
        survey_ids = opt[:total_ids] - survey_ids
      end
      opt[:surveys] = opt[:surveys].where(:_id.in => survey_ids) if survey_ids
    end
    if opt[:home_page].present? && opt[:surveys].size.to_i < 9
      extend_surveys = Survey.quillme_normal.closed.desc(:created_at).limit(9 - opt[:surveys].size.to_i)
      surveys = opt[:surveys] + extend_surveys
    end
    return surveys ||= opt[:surveys]
  end

  # Instance Methods
  delegate :count, :to => :answers,:prefix => true
  def scheme_id
    self.quillme_promote_info['reward_scheme_id']
  end

  # 查找某个sample 某个survey的answer
  def answer_by_sample(user=nil)
    self.answers.where(:is_preview => false,:user_id => user.id).first if user.present?
  end

  def excute_sample_data(user=nil)
    answer = answer_by_sample(user)
    self['answer_status'] = answer.try(:status) || 0
    self['answer_reject_type'] = answer.try(:reject_type) || 0
    self['reward_type_info'] = RewardScheme.first_reward_by_survey(self.scheme_id)
    return self
  end

  def self.get_reward_type_count(status = 2)
    status = 2 if status.blank?
    reward_types = Survey.quillme_normal.status(status).map{|s| s.quillme_promote_reward_type}
    reward_data = {}
    reward_types.uniq.each do |rt|
      reward_data[rt] = Survey.quillme_normal.status(status).where(:quillme_promote_reward_type => rt).count
    end
    return reward_data
  end

  def self.find_by_ids(survey_id_list)
    return Survey.all.in(_id: survey_id_list)
  end

  def update_quillme_promote_reward_type
    reward_scheme = RewardScheme.find_by_id(self.quillme_promote_info["reward_scheme_id"])
    self.update_attributes({"quillme_promote_reward_type" => 0}) and return if reward_scheme.nil?
    self.update_attributes({"quillme_promote_reward_type" => 0}) and return if reward_scheme.rewards.blank?
    self.update_attributes({"quillme_promote_reward_type" => reward_scheme.rewards[0]["type"].to_i})
  end

  def self.search(options = {})
    surveys = Survey.all
    surveys = survey.in(:status => Tool.convert_int_to_base_arr(options[:status])) if options[:status]
    surveys = surveys.where(:quillme_promotable => true) if options[:quillme_only].to_s == "true"
    case options[:keyword].to_s
    when /^.+@.+$/
      uid = User.where(:email => options[:keyword]).first.try '_id'
      surveys = surveys.where(:user_id => uid)
    when /^13[0-9]{9}|15[0|1|2|3|5|6|7|8|9]\d{8}|18[0|5|6|7|8|9]\d{8}/
      uid = User.where(:mobile => options[:keyword]).first.try '_id'
      surveys = surveys.where(:user_id => uid)
    when ''
      surveys
    else
      surveys = surveys.where(:title => /.*#{options[:keyword]}.*/)
    end
    surveys = surveys.desc(:star).desc(:created_at)

  end

  def update_promote(options)
    options.each do |promote_type, promote_info|
      next unless promote_info.is_a? Hash
      options[promote_type][:promotable] = promote_info[:promotable] == "true"
    end
    update_promote_info(options)
    update_agent_promote(options)
    serialize_in_promote_setting
  end

  def update_promote_info(options)
    filters = []
    options["broswer_extension"]["broswer_extension_promote_setting"]["filters"].each_value do |filter|
      filters << filter
    end
    options["broswer_extension"]["broswer_extension_promote_setting"]["filters"] = filters
    _promote_email_count = email_promote_info["promote_email_count"]
    _promote_sms_count = sms_promote_info["promote_sms_count"]
    [:quillme, :email, :sms, :broswer_extension, :weibo].each do |promote_type|
      _params = options[promote_type]
      self.update_attributes(
      "#{promote_type}_promotable".to_sym => _params[:promotable],
      "#{promote_type}_promote_info".to_sym => _params["#{promote_type}_promote_setting".to_sym]
      )
      update_quillme_promote_reward_type if options[promote_type] == :quillme
    end
    email_promote_info["promote_email_count"] = _promote_email_count
    sms_promote_info["promote_sms_count"] = _promote_sms_count
    save
  end

  def update_agent_promote(options)
    agents = []
    options["agent"]["agent_promote_setting"]["agents"].each_value do |agent|
      agent['survey_id'] = options[:id]
      if _agent_task = AgentTask.where(:_id => agent['task_id']).first
        agents << _agent_task.update_attributes(agent)
      else
        agents << AgentTask.create(agent)
      end
    end
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
     self.quality_control_questions_type = quality_control_questions_type
     self.quality_control_questions_ids = quality_control_questions_ids
     self.save
  end

  def set_spread(spread_point)
    self.spread_point = spread_point
    return self.save
  end

  def self.deadline_arrived(survey_id)
    s = Survey.find_by_id(survey_id)
    return if s.nil?
    return if s.deadline.nil?
    if Time.now.to_i - s.deadline < 20 && s.deadline - Time.now.to_i < 20
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

  def clone_survey(operator, title = nil)
    new_instance = self.clone
    new_instance.user = operator
    new_instance.update_attributes(title: title || new_instance.title, spread_point: 0)
    new_instance.answer_auditors.each { |a| new_instance.answer_auditors.delete(a) }
    question_id_mapping = new_instance.clone_page
    new_instance.clone_quota(question_id_mapping)
    new_instance.clone_filter(question_id_mapping)
    new_instance.clone_logic_control(question_id_mapping)
    new_instance.reward_scheme << RewardScheme.create(default: true)
    new_instance
  end

  def create_question(page_index, pre_question_id, question_type)
    if self.pages[page_index].nil?
      page_index = self.pages.length - 1
      create_page(page_index)
    end
    question = Question.create_question(question_type)
    insert_question(page_index, pre_question_id, question)
    question
  end

  def update_question(question_id, question_obj)
    question = Question.find_by_id(question_id)
    question.update_question(question_obj)
    adjust_logic_control_quota_filter('question_update', question_id)
    question
  end

  def move_question(question_id_1, page_index, question_id_2)
    remove_question(question_id_1, "to_be_deleted")
    create_page(page_index - 1) if self.pages[page_index].nil?
    insert_question(page_index, question_id_2, Question.find(question_id_1))
    remove_question("to_be_deleted")
    adjust_logic_control_quota_filter('question_move', question_id_1)
    self.save
  end

  def clone_question(question_id_1, page_index, question_id_2)
    orig_question = Question.find_by_id(question_id_1)
    new_question = orig_question.clone
    insert_question(page_index, question_id_2, new_question)
    self.save
    return new_question
  end

  def remove_question(question_id, replace = nil)
    self.pages.each do |page|
      index = page["questions"].index(question_id)
      if index.present?
        page["questions"].delete(question_id) if replace.nil?
        page["questions"][index] = replace if replace.present?
        break
      end
    end
    self.save
  end

  def delete_question(question_id)
    self.remove_question(question_id)
    adjust_logic_control_quota_filter('question_delete', question_id)
    Question.find(question_id).destroy
  end

  def all_questions(include_prg = true)
    q = (pages.map { |p| p["questions"] }).flatten
    ques = []
    q.collect do |i|
      que = Question.find(i)
      ques << que if (que.question_type != QuestionTypeEnum:: PARAGRAPH || include_prg)
    end
    ques
  end

  def all_questions_id(include_prg = true)
    q = (pages.map { |p| p["questions"] }).flatten
    return q if include_prg
    ques = []
    q.collect do |i|
      que = Question.find(i)
      ques << i if (que.question_type != QuestionTypeEnum:: PARAGRAPH || include_prg)
    end
    ques
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

  def adjust_logic_control_quota_filter(type, question_id)
    question = BasicQuestion.find_by_id(question_id)
    adjust_logic_control(question, type)
    self.adjust_quota(question, type)
    self.adjust_filter(question, type)
  end

  def check_password(username, password, is_preview)
    password_control = self.access_control_setting["password_control"]
    return true if password_control["password_type"] == -1
    return password_control["single_password"] == password if password_control["password_type"] == 0
    if password_control["password_type"] == 1
      list = password_control["password_list"]
      password_element = list.select { |ele| ele["content"] == password }[0]
    else
      list = password_control["username_password_list"]
      password_element = list.select { |ele| ele["content"] == [username, password] }[0]
    end
    return false if password_element.nil? || password_element["used"] != false
    return true if is_preview
    password_element["used"] = true
    return self.save
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
    headers =["answer_id", "email", "mobile", "IP"]
    self.all_questions(false).each_with_index do |e, i|
      headers += e.spss_header("q#{i+1}")
    end
    headers
  end

  def excel_header
    headers =["answer_id", "email", "mobile", "IP"]
    self.all_questions(false).each_with_index do |e, i|
      headers += e.excel_header("q#{i+1}")
    end
    headers
  end

  def csv_header(options = {})
    if options[:with] == "import_id"
      headers = ["import_id"]
      excel_headers = ["import_id"]
    else
      excel_headers = []
      headers = []
    end
    self.all_questions(false).each_with_index do |e, i|
      headers += e.csv_header("q#{i+1}")
    end
    if options[:text] == true
      self.all_questions(false).each_with_index do |e, i|
        excel_headers += e.excel_header("q#{i+1}").map { |e| e.gsub(',', ' ') }
      end
      return headers.to_csv + excel_headers.to_csv
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
    answer_length = answers.length
    last_time = Time.now.to_i
    answers.each_with_index do |answer, index|
      line_answer = [answer._id ,answer.user.email, answer.user.mobile, answer.ip_address]
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
    if !report_mockup_id.blank?
      report_mockup = self.report_mockups.find_by_id(report_mockup_id)
    end
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
    filter_conditions = filter_index == -1 ? [] : self.show_filter(filter_index)["conditions"]
    filtered_answers = []
    tot_num = screened_num = 0
    self.answers.not_preview.finished_and_screened.each_with_index do |a, index|
      next if !a.satisfy_conditions(filter_conditions)
      tot_num += 1
      screened_num += 1 if a.is_screened
      next if !include_screened_answer && a.is_screened
      filtered_answers << a
    end
    Task.set_progress(task_id, "find_answers_progress", 1.0)
    return [filtered_answers, tot_num, screened_num,
    self.answers.not_preview.ongoing.length, self.answers.not_preview.wait_for_review.length]
  end

  def self.list(status)
    status_ary = Tool.convert_int_to_base_arr(status)
    return Survey.where(:status.in => status_ary).desc(:created_at)
  end

  def self.search_title(query, operate_user)
    return Survey.where(title: Regexp.new(query.to_s)).desc(:created_at) if operate_user.is_admin?
    return operate_user.surveys.where(title: Regexp.new(query.to_s)).desc(:created_at)
  end

  def answer_status(user)
    return nil if user.nil?
    answer = Answer.where(:survey_id => self._id.to_s, :user_id => user._id.to_s, :is_preview => false)[0]
    return nil if answer.nil?
    return answer.status
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
    survey_obj["reward_schemes"] = self.reward_schemes.not_default
    survey_obj["agent_promote_info"] = {"_id" => self._id.to_s, "title" => self.title}
    if survey_obj["agent_promote_info"].present?
      survey_obj["agent_promotable"] = true
    end
    survey_obj["agent_promote_info"]["agents"] = Agent.all
    survey_obj["agent_promote_info"]["agent_tasks"] = self.agent_tasks
    unless survey_obj["agent_promote_info"]["agent_tasks"].present?
      survey_obj["agent_promote_info"]["agent_tasks"] = [{}]
    end
   if SampleAttribute.count > 0
      survey_obj["sample_attributes_list"] = SampleAttribute.normal
    else
      survey_obj["sample_attributes_list"] = [{}]
    end
    survey_obj["sample_attributes"] = sample_attributes
    return survey_obj
  end

  def sample_attributes
    smp_attrs = sample_attributes_for_promote
    smp_attrs.each_with_index do |smp_attr, index|
      smp_attr[:value] ||= smp_attr["value"]
      case smp_attr['type'].to_i
      when 0
        _value = smp_attr[:value]
      # when 1, 7
      #   _value = smp_attr[:value].join("\n")
      # when 2, 4
      #   _value = smp_attr[:value].map{|es| es.map { |e| e.join(',') }}.join("\n")
      # when 3, 5
      #   _value = smp_attr[:value].map{|es| es.map { |e| Time.at(e).strftime("%Y/%m/%d") }.join(',')}.join("\n")
      # when 6
      #   _value = smp_attr[:value].join("\n")
      else
        _value = smp_attr[:value]
      end
      smp_attrs[index]['value'] = _value
    end
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

  def answer_import(csv_str)
    updated_count = 0
    answer_bean = []
    CSV.parse(csv_str, :headers => true) do |row|
      return false if row.headers != self.csv_header(:with => "import_id")
      if imported_answer = self.answers.where(:import_id => row["import_id"].to_s).first
        imported_answer.update_attributes(:answer_content => parse_answer(row))
        updated_count += 1
      else
        answer_bean << generate_answer(row)
      end
    end
    Answer.collection.insert(answer_bean) if answer_bean.present?
    self.refresh_quota_stats
    self.save
    {
      :insert_count => answer_bean.length,
      :updated_count => updated_count,
      :error => ''
    }
  end

  def parse_answer(row)
    line_answer = {}
    all_questions_io.each_with_index do |qio, i|
      header_prefix = "q#{i + 1}"
      begin
        line_answer.merge! qio.answer_import(row.to_hash, header_prefix)
      rescue Exception => emsg
      end
    end
    line_answer
  end

  def all_questions_io
    @questions_io ||= all_questions(false).map do |question|
      Kernel.const_get(QuestionTypeEnum::QUESTION_TYPE_HASH["#{question.question_type}"] + "Io").new(question)
    end
  end

  def generate_answer(row)
    {:answer_content => parse_answer(row),
      :import_id => row["import_id"],
      :channel => -1,
      :survey_id => self._id,
      :status => 32,
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

  def set_quillme_hot(quillme_hot)
    if quillme_hot == true
      Survey.where(:quillme_hot => true).each_with_index do |s, index|
        if s._id != self._id
          s.quillme_hot = false
          s.save
        end
      end
      self.quillme_hot = true
    else
      self.quillme_hot = false
    end
    return self.save
  end

  def get_quillme_hot
    return self.quillme_hot == true
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
    s = SampleAttribute.normal.find_by_id(sample_attribute[:sample_attribute_id])
    return ErrorEnum::SAMPLE_ATTRIBUTE_NOT_EXIST if s.nil?
    sample_attribute[:type] = s.type
    if self.sample_attributes_for_promote.map{|sa| sa["sample_attribute_id"]}.include? sample_attribute[:sample_attribute_id]
      self.sample_attributes_for_promote.each do |smp_attr|
        if smp_attr["sample_attribute_id"] == sample_attribute[:sample_attribute_id]
          smp_attr["value"] = sample_attribute[:value]
        end
      end
    else
      self.sample_attributes_for_promote << sample_attribute
    end
    return self.save
  end

  def update_sample_attribute_for_promote(index, sample_attribute)
    s = SampleAttribute.normal.find_by_id(sample_attribute["sample_attribute_id"])
    return ErrorEnum::SAMPLE_ATTRIBUTE_NOT_EXIST if s.nil?
    self.sample_attributes_for_promote[index] = sample_attribute
    return self.save
  end

  def remove_sample_attribute_for_promote(sample_attribute_id)
    self.sample_attributes_for_promote.each_with_index do |smp_attr, i|
      if smp_attr["sample_attribute_id"] == sample_attribute_id
        self.sample_attributes_for_promote.delete_at(i)
      end
    end
    self.save
  end

  after_create do |doc|
    doc.reward_schemes << RewardScheme.create(default: true)
  end

  def remain_quota_number
    amount = 0
    self.quota["rules"].each do |r|
      amount += r["amount"] - r["finished_count"]
    end
    return amount
  end

  def cost_info
    cost_info = {mobile_cost: 0, alipay_cost: 0, point_cost: 0, lottery_cost: 0.0, jifenbao_cost: 0, introduce_number: 0}
    self.answers.not_preview.finished.each do |a|
      cost_info[:introduce_number] += 1 if a.introducer_id.present? && a.introducer_reward_assigned == true
      next if a.reward_delivered != true
      reward = (a.rewards.select { |e| e["checked"] == true }).first
      next if reward.blank?
      case reward["type"]
      when RewardScheme::MOBILE
        cost_info[:mobile_cost] += reward["amount"]
      when RewardScheme::ALIPAY
        cost_info[:alipay_cost] += reward["amount"]
      when RewardScheme::POINT
        cost_info[:point_cost] += reward["amount"]
      when RewardScheme::LOTTERY
        next if reward["win"] != true
        cost_info[:lottery_cost] += Prize.find(reward["win_prize_id"]).price
      when RewardScheme::JIFENBAO
        cost_info[:jifenbao_cost] += reward["amount"]
      end
    end
    cost_info
  end

  def max_num_per_ip_reached?(ip_address)
    return false if max_num_per_ip.blank? || max_num_per_ip <= 0
    return false if ip_address.blank?
    num_per_ip = self.answers.not_preview.where(ip_address: ip_address).length
    if num_per_ip >= self.max_num_per_ip
      return true
    end
    return false
  end

  def self.star(is_star)
    return self.criteria if is_star.blank?
    self.where(:is_star => is_star.to_s == "true")
  end
  
end
