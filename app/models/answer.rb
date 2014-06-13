# encoding: utf-8
require 'error_enum'
require 'data_type'
require 'securerandom'
require 'tool'
require 'quill_common'
Dir[File.dirname(__FILE__) + '/lib/survey_components/*.rb'].each {|file| require file }
class Answer

  include Mongoid::Document
  include Mongoid::Timestamps
  include FindTool

  # status
  NOT_EXIST = 0
  STATUS_NAME_ARY = ["edit", "reject", "under_review", "under_agent_review", "redo", "finish"]
  EDIT = 1
  REJECT = 2
  UNDER_REVIEW = 4
  UNDER_AGENT_REVIEW = 8
  REDO = 16
  FINISH = 32

  # reject type
  REJECT_BY_QUOTA = 1
  REJECT_BY_QUALITY_CONTROL = 2
  REJECT_BY_REVIEW = 4
  REJECT_BY_SCREEN = 8
  REJECT_BY_TIMEOUT = 16
  REJECT_BY_AGENT_REVIEW = 32
  REJECT_BY_IP_RESTRICT = 64
  REJECT_BY_ADMIN = 128

  # status: 1 for editting, 2 for reject, 4 for under review, 8 for for under agents' review, 16 for redo, 32 finish
  field :status, :type => Integer, default: 1
  field :answer_content, :type => Hash, default: {}
  field :random_quality_control_answer_content, :type => Hash, default: {}
  field :random_quality_control_locations, :type => Hash, default: {}
  field :logic_control_result, :type => Hash, default: {}
  field :repeat_time, :type => Integer, default: 0
  # reject_type: 1 for rejected by quota, 2 for rejected by quliaty control (auto quality control), 4 for rejected by manual quality control, 8 for rejected by screen, 16 for timeout
  field :reject_type, :type => Integer
  field :username, :type => String, default: ""
  field :password, :type => String, default: ""
  field :region, :type => Integer, default: -1
  #channel: 1（调研社区）2（邮件订阅），4（短信订阅），8（浏览器插件推送），16（微博发布），32（Folwy发布），64（线上代理发布)
  field :channel, :type => Integer
  field :ip_address, :type => String, default: ""
  field :remote_ip, :type => String, default: ""
  field :http_user_agent, :type => String, default: ""
  field :is_scanned, :type => Boolean, default: false
  field :is_preview, :type => Boolean, default: false
  field :finished_at, :type => Integer
  field :import_id, :type => String
  # audit time
  field :audit_at, :type => Integer
  # audit message content
  field :audit_message, :type => String, default: ""
  field :introducer_id, :type => String
  field :point_to_introducer, :type => Integer
  field :point, :type => Integer, :default => 0
  field :rewards, :type => Array, :default => []
  field :introducer_reward_assigned, :type => Boolean, default: false
  field :reward_delivered, :type => Boolean, default: false
  field :need_review, :type => Boolean
  # used for interviewer to upload attachments
  field :attachment, :type => Hash, :default => {}
  field :longitude, :type => String, :default => ""
  field :latitude, :type => String, :default => ""
  field :referrer, :type => String, :default => ""
  field :agent_feedback_name
  field :agent_feedback_email
  field :agent_feedback_mobile
  field :sample_attributes_updated, :type => Boolean, default: false
  field :suspected, :type => Boolean


  belongs_to :agent_task
  belongs_to :user, class_name: "User", inverse_of: :answers
  belongs_to :carnival_user
  belongs_to :survey
  belongs_to :interviewer_task
  belongs_to :lottery
  belongs_to :auditor, class_name: "User", inverse_of: :reviewed_answers
  belongs_to :reward_scheme
  has_one :order


  scope :not_preview, -> { where(:is_preview => false) }
  scope :preview, -> { where(:is_preview => true) }
  scope :finished, -> { where(:status => FINISH) }
  scope :screened, -> { where(:status => REJECT, :reject_type => REJECT_BY_SCREEN) }
  scope :finished_and_screened, -> { any_of({:status => FINISH}, {:status => REJECT, :reject_type => REJECT_BY_SCREEN}) }
  scope :rejected, -> { where(:status => REJECT) }
  scope :unreviewed, -> { where(:status => UNDER_REVIEW) }
  scope :ongoing, -> {where(:status => EDIT)}
  scope :wait_for_review, -> {where(:status => UNDER_REVIEW)}
  scope :my_spread, ->(user_id){ where(:introducer_id => user_id)}
  scope :special_status, ->(status){ where(:status.in => status.split(',')) }


  index({ introducer_id: 1 }, { background: true } )
  index({ survey_id: 1, is_preview: 1 }, { background: true } )
  index({ username: 1, password: 1 }, { background: true } )
  index({ is_preview: 1, introducer_id: 1 }, { background: true } )
  index({ survey_id: 1, status: 1, reject_type: 1 }, { background: true } )
  index({ status: 1, reject_type: 1 }, { background: true } )
  index({ created_at: 1 }, { background: true } ) 
  index({ user_id: 1, survey_id: 1, is_preview:1 }, { background: true } )
  index({ import_id:1},{ background: true })
  index({ ip_address:1},{ background: true })


  after_create do |doc|
    doc.region = QuillCommon::AddressUtility.find_address_code_by_ip(doc.ip_address) 
    doc.save
  end


  public

  def self.def_status_attr
    STATUS_NAME_ARY.each_with_index do |status_name, index|
      define_method("is_#{status_name}".to_sym) { return 2**index == self.status }
      define_method("set_#{status_name}".to_sym) { self.status = 2**index; self.save}
    end
  end

  def self.search(options)
    answers = self.not_preview
    answers = answers.find_by_status(options[:status]) if options[:status]
    answers = answers.find_by_status(options["status"]) if options["status"]
    if options[:keyword].present?
      if answers[0].carnival_user.present?
        c = CarnivalUser.where(mobile: options[:keyword]).first
        answers = answers.where(carnival_user_id: c.try(:_id))
      else
        if options[:keyword] =~ /^.+@.+$/
          options[:email] = options[:keyword]
        elsif /^\d{11}$/
          options[:mobile] = options[:keyword]
        else
          return answers.where(:_id => options[:keyword])
        end
        user = User.search_sample(options[:email], options[:mobile], true).first
        answers = answers.where(:user_id => user.try(:_id))
      end
    end
    answers  
  end  
  
  def_status_attr


  def self.find_by_survey_id_sample_id_is_preview(survey_id, sample_id, is_preview)
    return nil if sample_id.blank?
    return Answer.where(user_id: sample_id, survey_id: survey_id, :is_preview => is_preview).first
  end

  def self.find_by_survey_id_carnival_user_id_is_preview(survey_id, carnival_user_id, is_preview)
    return nil if carnival_user_id.blank?
    return Answer.where(carnival_user_id: carnival_user_id, survey_id: survey_id, :is_preview => is_preview).first
  end

  def self.find_by_status(status)
    if status.present?
      self.in("status" => Tool.convert_int_to_base_arr(status.to_i))
    else
      self.criteria
    end
  end

  def set_reject_with_type(reject_type, finished_at = Time.now.to_i)
    set_reject
    update_attributes(reject_type: reject_type)
    update_attributes(finished_at: finished_at) if self.finished_at.blank?
  end

  def self.create_answer(survey_id, reward_scheme_id, introducer_id, agent_task_id, answer_obj)
    answer = self.create(answer_obj)
    Survey.normal.find(survey_id).answers << answer
    # AgentTask.find_by_id(agent_task_id).try(:new_answer, answer)
    AgentTask.find(agent_task_id).new_answer(answer) if agent_task_id.present?
    RewardScheme.find(reward_scheme_id).new_answer(answer)
    answer.set_introducer_info(introducer_id)
      .init_answer_content
      .init_logic_control
      .genereate_random_quality_control_questions
  end

  def set_introducer_info(introducer_id)
    if !is_preview && introducer_id.present?
      introducer = User.sample.find_by_id(introducer_id)
      if introducer.present?
        self.introducer_id = introducer_id
        self.point_to_introducer = survey.spread_point
        SurveySpread.create_new(introducer, survey) 
      end
    end
    self.save
    self
  end

  def init_answer_content
    self.answer_content = {}
    survey.pages.each do |page|
      self.answer_content = answer_content.merge(Hash[page["questions"].map { |ele| [ele, nil] }])
    end
    survey.show_logic_control.each do |rule|
      if rule["rule_type"] == Survey::SHOW_QUESTION
        rule["result"].each do |q_id|
          self.answer_content[q_id] = {}
        end
      end
    end
    self.save
    self
  end

  def init_logic_control
    self.logic_control_result = {}
    survey.show_logic_control.each do |rule|
      if rule["rule_type"] == Survey::SHOW_ITEM
        rule["result"].each do |ele|
          add_logic_control_result(ele["question_id"], ele["items"], ele["sub_questions"])
        end
      elsif rule["rule_type"] == Survey::SHOW_CORRESPONDING_ITEM
        items_to_be_added = rule["result"]["items"].map { |input_ids| input_ids[1] }
        add_logic_control_result(rule["result"]["question_id_2"], items_to_be_added, [])
      end
    end
    self.save
    self
  end

  def genereate_random_quality_control_questions
    quality_control_questions_ids = []
    self.random_quality_control_answer_content = {}
    self.random_quality_control_locations = {}
    if answer_content.blank?
      self.save
      return self
    end
    if survey.is_random_quality_control_questions
      # need to select random questions
      # 1. determine the number of random quality control questions
      qc_question_number = [[answer_content.length / 10, 1].max, 4].min
      objective_question_number = (qc_question_number / 2.0).ceil
      matching_question_number = qc_question_number - objective_question_number
      # 2. randomly choose questions and generate locations of questions
      objective_questions_ids = QualityControlQuestion.objective_questions.shuffle[0..objective_question_number-1].map { |e| e._id.to_s }
      temp_matching_questions_ids = QualityControlQuestion.matching_questions.shuffle[0..matching_question_number-1].map { |e| e._id.to_s }
      matching_questions_ids = []
      temp_matching_questions_ids.each do |m_q_id|
        matching_questions_ids += MatchingQuestion.get_matching_question_ids(m_q_id)
      end
      quality_control_questions_ids = objective_questions_ids + matching_questions_ids
    else
      self.survey.quality_control_questions_ids.each do |qc_id|
        quality_control_question = QualityControlQuestion.find_by_id(qc_id)
        next if quality_control_question.nil?
        if quality_control_question.quality_control_type == 1
          # objective quality control question
          quality_control_questions_ids << qc_id
        else
          # matching quality control question
          quality_control_questions_ids += MatchingQuestion.get_matching_question_ids(qc_id)
        end
      end
    end
    quality_control_questions_ids.uniq!

    # 3. random generate locations for the quality control questions
    quality_control_questions_ids.each do |qc_id|
      normal_question_id = self.survey.all_questions_id.shuffle[0]
      self.random_quality_control_locations[normal_question_id] ||= []
      self.random_quality_control_locations[normal_question_id] << qc_id
    end
    # 4. initialize the random quality control questions answers
    self.random_quality_control_answer_content = Hash[quality_control_questions_ids.map { |ele| [ele, nil] }]
    self.save
    self
  end

  def is_screened
    return status == REJECT && reject_type == REJECT_BY_SCREEN
  end

  def load_question(question_id, next_page)
    pages_with_qc_questions = (survey.pages.map { |p| p["questions"] }).map do |page_question_ids|
      cur_page_questions = []
      page_question_ids.each do |q_id|
        cur_page_questions << q_id
        qc_ids = self.random_quality_control_locations[q_id] || []
        cur_page_questions += qc_ids
      end
      cur_page_questions
    end
    # consider the following scenario:
    # a normal question is removed, there are quality control questions after this normal question
    # such quality control questions are added to the last page
    remain_qc_ids = []
    self.random_quality_control_answer_content.each do |k, v|
      remain_qc_ids << k if !pages_with_qc_questions.flatten.include?(k)
    end
    pages_with_qc_questions << remain_qc_ids if !remain_qc_ids.blank?

    if self.survey.is_pageup_allowed
      # begin to find the question given
      pages_with_qc_questions.each_with_index do |page_questions, page_index|
        next if question_id.to_s != "-1" && !page_questions.include?(question_id)
        question_index = question_id.to_s == "-1" ? -1 : page_questions.index(question_id)
        if next_page
          if question_index + 1 == page_questions.length
            # should load next page questions
            return load_question_by_ids([]) if page_index + 1 == pages_with_qc_questions.length
            questions_ids = pages_with_qc_questions[page_index + 1]
            while questions_ids.blank?
              # if the next page has no questions, try to load questions in the page after the next
              page_index = page_index + 1
              return load_question_by_ids([]) if page_index + 1 == pages_with_qc_questions.length
              questions_ids = pages_with_qc_questions[page_index + 1]
            end
            return load_question_by_ids(questions_ids, next_page)
          else
            # should load remaining questions in the current page
            return load_question_by_ids(page_questions[question_index + 1..-1], next_page)
          end
        else
          if question_index <= 0
            # should load previous page questions
            return load_question_by_ids([]) if page_index == 0
            questions_ids = pages_with_qc_questions[page_index - 1]
            while questions_ids.blank?
              # if the previous page has no questions, try to laod questions in the page before the previous
              page_index = page_index - 1
              return load_question_by_ids([]) if page_index == 0
              questions_ids = pages_with_qc_questions[page_index - 1]
            end
            return load_question_by_ids(questions_ids, next_page)
          else
            # should load remaining questions in the current page
            return load_question_by_ids(page_questions[0..question_index - 1], next_page)
          end
        end
      end
      # the question cannot be found, load questions from the one with nil answer
      loaded_question_ids = []
      cur_page = false
      pages_with_qc_questions.each_with_index do |page_questions, page_index|
        page_questions.each do |q_id|
          # go to the next one if this questions has been answered
          next if ( !self.answer_content[q_id].nil? || !self.random_quality_control_answer_content[q_id].nil? ) && !cur_page
          cur_page = true
          loaded_question_ids << q_id
        end
        return load_question_by_ids(loaded_question_ids, next_page) if cur_page
      end
      return load_question_by_ids([])
    else
      loaded_question_ids = []
      # try to load normal questions
      # summarize the questions that are results of logic control rules
      logic_control_question_id = []
      self.survey.logic_control.each do |rule|
        if rule["rule_type"] == 0
          all_questions_id = self.survey.all_questions_id
          max_condition_index = -1
          rule["conditions"].each do |c|
            cur_index = all_questions_id.index(c["question_id"])
            max_condition_index = cur_index if !cur_index.nil? && cur_index > max_condition_index
          end
          result_q_ids = all_questions_id[max_condition_index+1..-1] if max_condition_index != -1
        end
        result_q_ids = rule["result"] if ["1", "2"].include?(rule["rule_type"].to_s)
        result_q_ids = rule["result"].map { |e| e["question_id"] } if ["3", "4"].include?(rule["rule_type"].to_s)
        result_q_ids = rule["result"]["question_id_2"].to_a if ["5", "6"].include?(rule["rule_type"].to_s)
        condition_q_ids = rule["conditions"].map {|condition| condition["question_id"]}
        logic_control_question_id << { "condition" => condition_q_ids, "result" => result_q_ids || [] }
      end
      cur_page = false
      pages_with_qc_questions.each do |page_questions|
        page_questions.each do |q_id|
          # check if this question is the result of some logic control rule
          if cur_page
            logic_control_question_id.each do |ele|
              if !(ele["condition"] & loaded_question_ids).empty? && ele["result"].include?(q_id)
                return load_question_by_ids(loaded_question_ids)
              end
            end
          end
          next if ( !self.answer_content[q_id].nil? || !self.random_quality_control_answer_content[q_id].nil? )
          cur_page = true
          loaded_question_ids << q_id
        end
        return load_question_by_ids(loaded_question_ids) if cur_page
      end
      return load_question_by_ids([])
    end
  end

  def load_question_by_ids(question_ids, next_page = true)
    finish(true) if question_ids.blank? && !self.survey.is_pageup_allowed
    questions = []
    question_ids.each do |q_id|
      question = BasicQuestion.find_by_id(q_id)
      questions << question.remove_hidden_items(logic_control_result[q_id]) if !question.nil?
    end
    # consider the scenario that "one question per page"
    return questions if !self.survey.style_setting["is_one_question_per_page"]
    return [] if questions.blank?
    return [questions[0]] if next_page
    return [questions[-1]]
  end

  def add_logic_control_result(question_id, items, sub_questions)
    return if self.survey.is_pageup_allowed
    if self.logic_control_result[question_id].nil?
      self.logic_control_result[question_id] = {"items" => items, "sub_questions" => sub_questions}
    else
      self.logic_control_result[question_id]["items"] =
        (self.logic_control_result[question_id]["items"].to_a + items.to_a).uniq
      self.logic_control_result[question_id]["sub_questions"] =
        (self.logic_control_result[question_id]["sub_questions"].to_a + sub_questions.to_a).uniq
    end
    self.save
  end

  def remove_logic_control_result(question_id, items, sub_questions)
    return if self.survey.is_pageup_allowed
    return if self.logic_control_result[question_id].nil?
    cur_items = self.logic_control_result[question_id]["items"].to_a
    cur_sub_questions = self.logic_control_result[question_id]["sub_questions"].to_a
    (items || []).each do |ele|
      cur_items.delete(ele)
    end
    (sub_questions || []).each do |ele|
      cur_sub_questions.delete(ele)
    end
    self.logic_control_result[question_id]["items"] = cur_items
    self.logic_control_result[question_id]["sub_questions"] = cur_sub_questions
    self.save
  end

  def satisfy_conditions(conditions, refresh_quota = true)
    # only answers that are finished contribute to quotas
    return false if !self.is_finish && refresh_quota
    (conditions || []).each do |condition|
      satisfy = false
      case condition["condition_type"].to_s
      when "1"
        question_id = condition["name"]
        question = BasicQuestion.find_by_id(question_id)
        if question.nil? || answer_content[question_id].nil?
          satisfy = true
        elsif question.question_type == QuestionTypeEnum::CHOICE_QUESTION
          satisfy = Tool.check_choice_question_answer(question_id,
                              self.answer_content[question_id]["selection"] || [],
                              condition["value"],
                              condition["fuzzy"])
        elsif question.question_type == QuestionTypeEnum::ADDRESS_BLANK_QUESTION
          satisfy = Tool.check_address_blank_question_answer(question_id,
                              self.answer_content[question_id]["selection"] || [],
                              condition["value"])
        end
      when "2"
        satisfy = QuillCommon::AddressUtility.satisfy_region_code?(self.region, condition["value"])
      when "3"
        satisfy = condition["value"] == self.channel.to_s
      when "4"
        satisfy = Tool.check_ip_mask(condition["value"], self.ip_address)
      end
      return false if !satisfy
    end
    true
  end

  def clear
    return ErrorEnum::WRONG_ANSWER_STATUS if self.is_finish || self.is_reject
    self.init_answer_content
      .init_logic_control
      .genereate_random_quality_control_questions
      .set_edit
    true
  end

  def update_status
    # an answer expires only when the survey is not published and the answer is in editting status
    if Time.now.to_i - self.created_at.to_i > 2.days.to_i && self.survey.status != Survey::PUBLISHED && self.status == EDIT
      set_reject_with_type(REJECT_BY_TIMEOUT)
    end
    return self.status
  end

  def delete
    # only answers that are finished can be deleted
    return ErrorEnum::WRONG_ANSWER_STATUS if self.is_redo || self.is_edit
    return self.destroy
  end

  def update_answer(new_answer)
    # it might happen that:
    # survey has a new question, but the answer content does not has the question id as a key
    # thus when updating the answer content, the key should not be checked
    new_answer.each do |k, v|
      v["selection"] ||= [] if v.class == Hash && v.has_key?("selection")
      self.answer_content[k] = v if self.answer_content.has_key?(k)
      self.random_quality_control_answer_content[k] = v if self.random_quality_control_answer_content.has_key?(k)
      if self.answer_content[k].nil?
        q = Question.find(k)
        self.answer_content[k] = {} if q.is_required == false
      end
    end
    self.save
    return true
  end

  def check_quality_control(new_answer)
    random_quality_control_question_id_ary = []
    new_answer.each do |k, v|
      question = BasicQuestion.find_by_id(k)
      random_quality_control_question_id_ary << k if !question.nil? && question.class == QualityControlQuestion
    end
    random_quality_control_question_id_ary.each do |qc_id|
      if !QualityControlQuestion.check_quality_control_answer(qc_id, self)
        update_attributes(repeat_time: repeat_time + 1)
        repeat_time == 1 ? set_redo : set_reject_with_type(REJECT_BY_QUALITY_CONTROL)
        return false
      end
    end
    true
  end

  def check_screen(new_answer)
    survey.show_logic_control.each do |logic_control_rule|
      next if logic_control_rule["rule_type"] != Survey::SCREEN
      condition_qid_ary = logic_control_rule["conditions"].map {|ele| ele["question_id"]}
      next if (new_answer.keys & condition_qid_ary).empty?
      # for each condition, check whether it is violated
      pass_condition = true
      logic_control_rule["conditions"].each do |condition|
        # if the volunteer has not answered this question, stop the checking of this rule
        break if answer_content[condition["question_id"]].nil?
        pass_condition &&= Tool.check_choice_question_answer(condition["question_id"],
                                answer_content[condition["question_id"]]["selection"],
                                condition["answer"],
                                condition["fuzzy"])
      end
      set_reject_with_type(REJECT_BY_SCREEN) and return false if pass_condition
    end
    true
  end

  def check_question_quota(answer_content)
    quota = self.survey.show_quota
    return true if !quota["is_exclusive"]
    has_related_rule = false
    quota["rules"].each do |rule|
      question_ids = []
      (rule["conditions"] || []).each do |c|
        question_ids << c["name"] if c["condition_type"].to_i == 1
      end
      has_related_rule = true if (answer_content.keys & question_ids).present?
      return true if self.satisfy_conditions(rule["conditions"], false) && rule["submitted_count"] < rule["amount"]
    end
    return true unless has_related_rule
    set_reject_with_type(REJECT_BY_QUOTA)
    false
  end

  def check_channel_ip_address_quota
    # 1. get the corresponding survey, quota, and quota stats
    quota = self.survey.quota
    # 2. if all quota rules are satisfied, the new answer should be rejected
    set_reject_with_type(REJECT_BY_QUOTA) and return false if quota["quota_satisfied"]
    # 3 else, if the "is_exclusive" is set as false, the new answer should be accepted
    return true if !quota["is_exclusive"]
    # 4 the rules should be checked one by one to see whether this answer can be satisfied
    quota["rules"].each do |rule|
      # move to next rule if the quota of this rule is already satisfied
      next if rule["submitted_count"] >= rule["amount"]
      (rule["conditions"] || []).each do |condition|
        # if the answer's ip, channel, or region violates one condition of the rule, move to the next rule
        next if condition["condition_type"] == 2 && !QuillCommon::AddressUtility.satisfy_region_code?(self.region, condition["value"])
        next if condition["condition_type"] == 3 && self.channel != condition["value"]
        next if condition["condition_type"] == 4 && Tool.check_ip_mask(self.ip_address, condition["value"])
      end
      # find out one rule. the quota for this rule has not been satisfied, and the answer does not violate conditions of the rule
      return true
    end
    # 5 cannot find a quota rule to accept this new answer
    set_reject_with_type(REJECT_BY_QUOTA)
    false
  end

  def update_logic_control_result(new_answer)
    return if survey.is_pageup_allowed
    survey.show_logic_control.each do |logic_control_rule|
      # if the answers submitted have nothing to do with the conditions of this rule, move to the next rule
      condition_qid_ary = logic_control_rule["conditions"].map {|condition| condition["question_id"]}
      next if (new_answer.keys & condition_qid_ary).empty?
      satisfy_rule = true
      logic_control_rule["conditions"].each do |condition|
        satisfy_rule = false if answer_content[condition["question_id"]].nil?
        pass_condition = Tool.check_choice_question_answer(condition["question_id"],
                                answer_content[condition["question_id"]]["selection"],
                                condition["answer"],
                                condition["fuzzy"])
        satisfy_rule = false if !pass_condition
      end
      next if !satisfy_rule
      # the conditions of this logic control rule is satisfied
      case logic_control_rule["rule_type"].to_i
      when Survey::SHOW_QUESTION
        # if the rule is satisfied, show the question (set the answer of the question as "nil")
        logic_control_rule["result"].each { |q_id| self.answer_content[q_id] = nil }
        self.save
      when Survey::HIDE_QUESTION
        # if the rule is satisfied, hide the question (set the answer of the question as {})
        logic_control_rule["result"].each { |q_id| self.answer_content[q_id] ||= {} }
        self.save
      when Survey::SHOW_ITEM
        # if the rule is satisfied, show the items (remove from the logic_control_result)
        logic_control_rule["result"].each { |ele| remove_logic_control_result(ele["question_id"], ele["items"], ele["sub_questions"]) }
      when Survey::HIDE_ITEM
        # if the rule is satisfied, hide the items (add to the logic_control_result)
        logic_control_rule["result"].each { |ele| add_logic_control_result(ele["question_id"], ele["items"], ele["sub_questions"]) }
      when Survey::SHOW_CORRESPONDING_ITEM
        # if the rule is satisfied, show the items (remove from the logic_control_result)
        items_to_be_removed = log_control_rule["result"]["items"].map { |input_ids| input_ids[1] } || []
        remove_logic_control_result(logic_control_rule["result"]["question_id_2"], items_to_be_removed, [])
      when Survey::HIDE_CORRESPONDING_ITEM
        # if the rule is satisfied, hide the items (add to the logic_control_result)
        items_to_be_added = log_control_rule["result"]["items"].map { |input_ids| input_ids[1] } || []
        add_logic_control_result(logic_control_rule["result"]["question_id_2"], items_to_be_added, [])
      end
    end
  end

  # return the index of the first given question in all the survey questions
  def index_of(questions, all = false)
    return nil if questions.blank?
    question_id = nil
    if all == false
      questions.each do |q|
        if q.question_type != QuestionTypeEnum::PARAGRAPH
          question_id = q._id.to_s
          break
        end
      end
    else
      question_id = questions[0].id.to_s
    end
    question_ids = self.survey.all_questions_id(all)
    question_ids_with_qc_questions = []
    question_ids.each do |qid|
      question_ids_with_qc_questions << qid
      question_ids_with_qc_questions += self.random_quality_control_locations[qid] if !self.random_quality_control_locations[qid].blank?
    end
    return question_ids_with_qc_questions.index(question_id)
  end

  def finish(auto = false)
    sync_questions
    # surveys that allow page up cannot be finished automatically
    return false if self.survey.is_pageup_allowed && auto
    # check whether can finish this answer
    return ErrorEnum::WRONG_ANSWER_STATUS if !self.is_edit
    return ErrorEnum::ANSWER_NOT_COMPLETE if self.answer_content.has_value?(nil)
    return ErrorEnum::ANSWER_NOT_COMPLETE if self.random_quality_control_answer_content.has_value?(nil)
    old_status = self.status
    # if the survey has no prize and cannot be spreadable (or spread reward point is 0), set the answer as finished
    if self.agent_task.present?
      self.set_under_agent_review
    elsif self.is_preview || !self.need_review
      self.set_finish
      Carnival.pre_survey_finished(self.id) if self.survey_id.to_s == Carnival::PRE_SURVEY
      Carnival.background_survey_finished(self.id) if self.survey_id.to_s == Carnival::BACKGROUND_SURVEY
    else
      self.set_under_review
      Carnival.survey_finished(self.id) if Carnival::SURVEY.include?(self.survey_id.to_s)
    end
    self.update_quota(old_status) if !self.is_preview
    self.finished_at = Time.now.to_i
    self.deliver_reward
    self.update_sample_attributes if !self.is_preview && self.is_finish
    self.save

    if Carnival::SURVEY.include?(self.survey.id.to_s)
      self.check_contradiction
    end
  end

  def sync_questions
    survey_question_ids = survey.all_questions_id
    self.answer_content.delete_if { |q_id, a| !survey_question_ids.include?(q_id) }
    survey_question_ids.each do |q_id|
      self.answer_content[q_id] ||= nil
    end
    self.random_quality_control_answer_content.delete_if { |q_id, a| QualityControlQuestion.find_by_id(q_id).nil? }
    self.save
    self
  end

  def update_quota(old_status)
    survey.update_quota(self, old_status)
    interviewer_task.try(:refresh_quota)
    agent_task.try(:refresh_quota)
    self
  end

  def admin_reject(admin)
    # only finished answers can be rejected by admin
    return false if self.status != FINISH
    # set reject and reject type
    set_reject_with_type(REJECT_BY_ADMIN)
    if self.user.present?
      # send sample a message
      message_title = "对不起,您参与的问卷未通过审核!"
      message_content = "您参与的问卷[#{self.survey.title}]没有通过管理员审核"
      admin.create_message(message_title, message_content, [self.user._id.to_s])
      update_attributes(audit_message: message_content, auditor: admin, audit_at: Time.now.to_i)
      # decrease the sample's point
      self.rewards.each do |r|
        if r["checked"] == true && r["type"] == RewardScheme::POINT
          sample = self.user
          amount = [sample.point, r["amount"].to_i].min
          sample.point = sample.point - amount
          sample.save
          PointLog.create_admin_operate_point_log(-amount, "您参与的问卷[#{self.survey.title}]没有通过管理员审核", sample.id)
          self.rewards.each { |e| e["checked"] = false }
          self.save
        end
      end
    end
  end

  def review(review_result, answer_auditor, message)
    # return false if self.status != UNDER_REVIEW
    old_status = self.status
    if review_result
      return false if self.status == FINISH
      self.set_finish
      self.update_sample_attributes
      message_title = "问卷[#{self.survey.title}]通过审核!"
      message_content = "您参与的[#{self.survey.title}]已通过审核,感谢参与."
    else
      return false if self.status == REJECT || self.status == REDO
      set_reject_with_type(REJECT_BY_REVIEW)
      message_title = "对不起,您参与的问卷未通过审核!"
      message_content = "您参与的问卷[#{self.survey.title}]没有通过管理员审核"
      message_content += ", 拒绝原因: #{message}" if message.present?
      PunishLog.create_punish_log(user.id) if user.present?
    end
    Carnival.survey_reviewed(self.id) if Carnival::SURVEY.include?(self.survey_id.to_s)
    answer_auditor.create_message(message_title, message_content, [user._id.to_s]) if user.present?
    update_attributes(audit_message: message_content, auditor: answer_auditor, audit_at: Time.now.to_i)
    interviewer_task.try(:refresh_quota)
    update_quota(old_status).deliver_reward
    true
  end

  def agent_review(review_result)
    return false if self.status != UNDER_AGENT_REVIEW
    review_result ? set_under_review : set_reject_with_type(REJECT_BY_AGENT_REVIEW)
    save
    agent_task.try(:refresh_quota)
    true
  end

  def assign_introducer_reward
    return unless status == FINISH
    # give the introducer points
    introducer = User.find_by_id(self.introducer_id)
    if introducer.present? && self.introducer_reward_assigned == false
      # update the survey spread
      SurveySpread.inc(introducer, self.survey)
      if point_to_introducer > 0
        introducer.point = introducer.point + self.point_to_introducer
        introducer.save
        PointLog.create_spread_point_log(self.point_to_introducer, self.survey._id.to_s, self.survey.title, introducer._id)
        # send the introducer a message about the rewarded points
        introducer.create_message("问卷推广积分奖励", "您推荐填写的问卷通过了审核，您获得了#{self.point_to_introducer}个积分奖励。", [introducer._id.to_s])
      end
      self.introducer_reward_assigned = true
    end
  end

  def select_reward(type, account, current_sample)
    return ErrorEnum::HOT_SURVEY if self.check_for_hot_survey(account, current_sample)
    self.rewards.each { |r| r["checked"] = false }
    case type
    when "chongzhi"
      index = self.rewards.index { |e| e["type"].to_i == RewardScheme::MOBILE }
      self.rewards[index]["mobile"] = account
      self.rewards[index]["checked"] = true
    when "zhifubao", "jifenbao"
      index = self.rewards.index { |e| [RewardScheme::ALIPAY, RewardScheme::JIFENBAO].include?(e["type"].to_i) }
      self.rewards[index]["alipay_account"] = account
      self.rewards[index]["checked"] = true
    end
    self.save
    self.deliver_reward
  end

  def check_for_hot_survey(account, current_sample)
    return false if survey.quillme_hot != true
    return true if user.answers.not_preview.length > 0 && user.present?
    return true if user.blank? && current_sample && current_sample.answers.not_preview.length > 0
    sample = User.sample.find_by_email_or_mobile(account)
    return true if sample && sample.answers.not_preview.length > 0
    false
  end

  def handle_cash_order(reward)
    if order.nil?
      order =
        case reward["type"].to_i
        when RewardScheme::MOBILE
          Order.create_answer_mobile_order(self, reward)
        when RewardScheme::ALIPAY
          Order.create_answer_alipay_order(self, reward)
        when RewardScheme::JIFENBAO
          Order.create_answer_jifenbao_order(self, reward)
        end
      return true if status == UNDER_REVIEW
      update_attributes({ "reward_delivered" => true })
    elsif self.order.status == Order::FROZEN
      self.order.update_status
      self.update_attributes({"reward_delivered" => true}) if [FINISH, REJECT].include?(self.status)
    end
  end

  def deliver_reward
    assign_introducer_reward
    return true if self.reward_delivered
    reward = nil
    self.rewards.each do |r|
      reward = r and break if r["checked"] == true
    end
    return ErrorEnum::REWARD_NOT_SELECTED if reward.nil?
    case reward["type"].to_i
    when RewardScheme::MOBILE
      return ErrorEnum::REPEAT_ORDER if self.check_repeat_order(reward["mobile"])
      handle_cash_order(reward)
    when RewardScheme::ALIPAY
      return ErrorEnum::REPEAT_ORDER if self.check_repeat_order(reward["alipay_account"])
      handle_cash_order(reward)
    when RewardScheme::JIFENBAO
      return ErrorEnum::REPEAT_ORDER if self.check_repeat_order(reward["alipay_account"])
      handle_cash_order(reward)
    when RewardScheme::POINT
      return true if self.status == UNDER_REVIEW
      self.update_attributes({"reward_delivered" => true}) and return true if self.status == REJECT
      user = self.user
      if user.present?
        user.update_attributes(point: user.point + reward["amount"])
        PointLog.create_answer_point_log(reward["amount"], self.survey_id.to_s, self.survey.title, user._id)
        self.update_attributes({"reward_delivered" => true})
      end
    when RewardScheme::LOTTERY
      return true if self.status == UNDER_REVIEW
      if self.order && self.order.status == Order::FROZEN
        self.order.update_status(false)
        self.update_attributes({"reward_delivered" => true})
      end
    end
    true
  end

  def check_repeat_order(account)
    self.survey.answers.each do |a|
      next if a._id.to_s == self._id.to_s
      selected_reward = a.rewards.select { |r| r["checked"] == true }
      next if selected_reward.blank?
      return true if selected_reward[0]["mobile"] == account || selected_reward[0]["alipay_account"] == account
    end
    return false
  end

  def bind_sample(sample)
    answer = Answer.find_by_survey_id_sample_id_is_preview(self.survey._id.to_s, sample._id.to_s, false)
    return ErrorEnum::ANSWER_EXIST if answer.present?
    sample.answers << self
    self.update_sample_attributes if self.is_finish
    PunishLog.create_punish_log(sample.id) if self.status == REJECT
    if self.auditor.present?
      self.auditor.create_message("审核问卷答案消息", self.audit_message, [sample._id.to_s])
    end
    # handle rewards
    reward = nil
    self.rewards.each do |r|
      reward = r and break if r["checked"] == true
    end
    return true if reward.nil?
    case reward["type"].to_i
    when RewardScheme::MOBILE
      sample.orders << self.order unless self.order.nil?
    when RewardScheme::ALIPAY
      sample.orders << self.order unless self.order.nil?
    when RewardScheme::JIFENBAO
      sample.orders << self.order unless self.order.nil?
    when RewardScheme::LOTTERY
      sample.orders << self.order unless self.order.nil?
    when RewardScheme::POINT
      self.deliver_reward
    end
    return true
  end

  def draw_lottery(user_id)
    return ErrorEnum::LOTTERY_DRAWED if self.reward_delivered
    reward = (self.rewards.select { |r| r["checked"] == true }).first
    return ErrorEnum::REWORD_NOT_SELECTED if reward.nil?
    return ErrorEnum::NOT_LOTTERY_REWARD if reward["type"] != RewardScheme::LOTTERY
    return ErrorEnum::LOTTERY_DRAWED if !reward["win"].nil?

    reward_scheme = self.reward_scheme
    return {"result" => false} if reward_scheme.nil? || reward_scheme.rewards[0]["type"].to_i != RewardScheme::LOTTERY
    rewards_from_scheme = reward_scheme.rewards[0]

    reward["prizes"].each do |p|
      next if rand > p["prob"].to_f
      rewards_from_scheme["prizes"].each do |prize_from_scheme|
        next if p["id"] != prize_from_scheme["id"]
        if prize_from_scheme["deadline"] > Time.now.to_i && prize_from_scheme["amount"].to_i > prize_from_scheme["win_amount"].to_i
          reward["win"] = true
          reward["prize_id"] = p["id"]
          self.save
          prize_from_scheme["win_amount"] ||= 0
          prize_from_scheme["win_amount"] += 1
          reward_scheme.save
          return {"result" => true,
            "prize_id" => p["id"],
            "prize_title" => Prize.normal.find_by_id(p["id"]).try(:title)}
        end
      end
    end
    reward["win"] = false
    self.reward_delivered = true
    self.save
    LotteryLog.create_fail_lottery_log(answer_id:self.id,
                                        survey_id:self.survey.id,
                                        survey_title:self.survey.title,
                                        user_id:user_id,
                                        ip:self.ip_address)
    return {"result" => false}
  end

  def create_lottery_order(order_info)
    #return ErrorEnum::SAMPLE_NOT_EXIST if self.user.nil?
    return ErrorEnum::ORDER_CREATED if !self.order.nil?
    reward = (self.rewards.select { |r| r["checked"] == true }).first
    return ErrorEnum::REWORD_NOT_SELECTED if reward.nil?
    return ErrorEnum::NOT_LOTTERY_REWARD if reward["type"] != RewardScheme::LOTTERY
    return ErrorEnum::NOT_WIN if reward["win"] != true

    # create lottery order
    order_info.merge!("status" => Order::FROZEN) if self.status == UNDER_REVIEW
    order = Order.create_lottery_order(self.id,self.user.try(:_id),
      self.survey._id.to_s,
      reward["prize_id"],
      self.ip_address,
      order_info)
    self.order = order
    return true
  end

  def info_for_auditor
    sample_name = self.user.try(:email) || self.user.try(:mobile) || "visitor"
    self.write_attribute('sample_name', sample_name)
    return self
  end

  def info_for_sample
    answer_obj = {}
    answer_obj["survey_id"] = self.survey_id.to_s
    answer_obj["survey_title"] = self.survey.title
    answer_obj["is_preview"] = self.is_preview
    answer_obj["rewards"] = self.rewards
    answer_obj["sample_id"] = self.user.nil? ? nil : self.user._id.to_s
    answer_obj["reward_scheme_id"] = self.reward_scheme_id.to_s
    return answer_obj
  end

  def present_auditor
    answer = self
    # audited, if not.
    answer['auditor_email'] = answer.auditor.email if answer.auditor

    answer["question_content"] = []
    answer.answer_content.each do |key, val|
      # key is question id
      # val is like of { "selection" : [ NumberLong("1351400998231222"), NumberLong("3055564856809646") ], "text_input" : "" }
      question = Question.find_by_id(key)
      next unless question
      show_answer = {'question_type' => question.question_type, 
          "title" => question.content["text"]}

      case question.question_type
      when QuestionTypeEnum::CHOICE_QUESTION
        # 选择题
        # Example:
        # show_answer = {'question_type'=> 0,
        #     'question_type_label'=> '选择题',
        #     'title' => 'XXXXXXXXXXX',
        #     'choices' => ['aaa', 'bbb', 'ccc'],
        #     'selected_choices' => ['aaa', 'bbb']
        #   }
        show_answer.merge!({'question_type_label'=> '选择题'})
        answer["question_content"] << show_answer and next if val.blank?

        val["selection"] ||= []
        if question.issue["items"] 
          choices = []
          selected_choices = []
          question.issue["items"].each do |item|
            choices << item["content"]["text"]
            val["selection"].each do |selection_id|
              selected_choices << item["content"]["text"] if selection_id.to_s == item["id"].to_s
            end
          end
          if question.issue["other_item"]["has_other_item"]
            if val["selection"].include?(question.issue["other_item"]["id"])
              selected_choices << "#{question.issue["other_item"]["content"]["text"]}:#{val["text_input"]}"
            end
            choices << question.issue["other_item"]["content"]["text"]
          end
          show_answer.merge!({"choices"=>choices})
          show_answer.merge!({"selected_choices"=> selected_choices})
        end
        answer["question_content"] << show_answer
      when QuestionTypeEnum::MATRIX_CHOICE_QUESTION 
        # 矩阵选择题
        # Example:
        # show_answer = {'question_type' => 1 ,
        #     'question_type_label'=> '矩阵选择题',
        #     'title'=>'XXXXXXXXXXX',
        #     'choices' => ['aaa', 'bbb', 'ccc'],
        #     'rows' => ['a1', 'a2'],
        #     'rows_selected_choices' => [["aaa",'bbb'], ['aaa']]
        # }
        show_answer.merge!({'question_type_label'=> '矩阵选择题'})
        answer["question_content"] << show_answer and next if val.blank?

        choices = []
        rows = []
        rows_selected_choices = []

        question.issue["items"].each do |item|
          choices << item["content"]["text"]
        end
        show_answer.merge!({"choices"=>choices})
      
        question.issue['rows'].each_with_index do |item, index|
          rows << item['content']['text']
          row_selected_choices = []
          (val[item['id'].to_s] || []).each do |choice_id|
            question.issue["items"].each do |e|
              row_selected_choices << e["content"]["text"] if choice_id.to_s == e['id'].to_s
            end
          end
          rows_selected_choices << row_selected_choices
        end
        show_answer.merge!({"rows"=>rows, "rows_selected_choices"=>rows_selected_choices})
        answer["question_content"] << show_answer
      when QuestionTypeEnum::TEXT_BLANK_QUESTION
        # 文本填充题
        # Example:
        # show_answer = {'question_type' => 2 ,
        #     'question_type_label'=> '文本填充题',
        #     'title'=>'XXXXXXXXXXX',
        #   'content' => 'XXXXXXXXXXX'
        # }
        show_answer.merge!({'question_type_label'=> '文本填充题'})
        answer["question_content"] << show_answer and next if val.blank?

        show_answer.merge!({"content"=> val.to_s})
        answer["question_content"] << show_answer
      when QuestionTypeEnum::NUMBER_BLANK_QUESTION
        # 数值填充题
        # Example:
        # show_answer = {'question_type' => 3 ,
        #     'question_type_label'=> '数值填充题',
        #     'title'=>'XXXXXXXXXXX',
        #   'content' => '23.5'
        # } 
        show_answer.merge!({'question_type_label'=> '数值填充题'})
        answer["question_content"] << show_answer and next if val.blank?

        show_answer.merge!({"content"=> val.to_s})
        answer["question_content"] << show_answer
      when QuestionTypeEnum::EMAIL_BLANK_QUESTION
        # 邮箱题
        # Example:
        # show_answer = {'question_type' => 4 ,
        #     'question_type_label'=> '邮箱题',
        #     'title'=>'XXXXXXXXXXX',
        #   'content' => '23.5'
        # } 
        show_answer.merge!({'question_type_label'=> '邮箱题'})
        answer["question_content"] << show_answer and next if val.blank?

        show_answer.merge!({"content"=> val.to_s})
        answer["question_content"] << show_answer
      when QuestionTypeEnum::URL_BLANK_QUESTION
        # 网址链接题
        # Example:
        # show_answer = {'question_type' => 5 ,
        #     'question_type_label'=> '网址链接题',
        #     'title'=>'XXXXXXXXXXX',
        #   'content' => 'www.baidu.com'
        # } 

        show_answer.merge!({'question_type_label'=> '网址链接题'})
        answer["question_content"] << show_answer and next if val.blank?

        show_answer.merge!({"content"=> val.to_s})
        answer["question_content"] << show_answer
      when QuestionTypeEnum::PHONE_BLANK_QUESTION
        # 电话题
        # Example:
        # show_answer = {'question_type' => 6 ,
        #     'question_type_label'=> '电话题',
        #     'title'=>'XXXXXXXXXXX',
        #   'content' => '010-8888-8888'
        # } 
        show_answer.merge!({'question_type_label'=> '电话题'})
        answer["question_content"] << show_answer and next if val.blank?

        show_answer.merge!({"content"=> val.to_s})
        answer["question_content"] << show_answer
      when QuestionTypeEnum::TIME_BLANK_QUESTION
        # 时间题
        # Example:
        # show_answer = {'question_type' => 7 ,
        #     'question_type_label'=> '时间题',
        #     'title'=>'XXXXXXXXXXX',
        #   'content' => '2012-01-01'
        # } 
        show_answer.merge!({'question_type_label'=> '时间题'})
        answer["question_content"] << show_answer and next if val.blank?

        show_answer.merge!({"content"=> Time.at(val.to_i/1000).strftime("%F")})
        answer["question_content"] << show_answer
      when QuestionTypeEnum::ADDRESS_BLANK_QUESTION
        # 地址题
        # Example:
        # show_answer = {'question_type' => 8 ,
        #     'question_type_label'=> '地址题',
        #     'title'=>'XXXXXXXXXXX', 
        #   'address' => 'city-code',
        #   'detail' => 'XXXXXXXXXXXX',
        #   'postcode' => '100083',
        # } 
        show_answer.merge!({'question_type_label'=> '地址题'})
        answer["question_content"] << show_answer and next if val.blank?

        town =  QuillCommon::AddressUtility.find_province_city_town_by_code(val["address"].to_i)

        show_answer.merge!({"address"=> town, 
          "detail" => val["detail"],
          "postcode" => val["postcode"].to_i})
        answer["question_content"] << show_answer
      when QuestionTypeEnum::BLANK_QUESTION
        # 组合填充题
        # Example:
        # show_answer = {'question_type' => 9 ,
        #     'question_type_label'=> '组合填充题',
        #     'title'=>'XXXXXXXXXXX',
        #     'items' => [
        #       {
        #         'data_type' => 'Text',
        #         'title' => 'XXXXXXXXXXX',
        #         'content' => 'XX'
        #       },
        #       ...
        #     ]
        #   }
        show_answer.merge!({'question_type_label'=> '组合填充题'})

        questions = []
        show_answer['items'] = []
        question.issue['items'].each_with_index do |item, index|
          sub_question = {'data_type' => item['data_type'].to_s, 
            'title' => item['content']['text']}
          case item['data_type'].to_s
          when 'Text','Time','Number','Phone','Email','Url'
            sub_question.merge!({ 'content'=> val[index]})
          when 'Address'
            town =  QuillCommon::AddressUtility.find_text_by_code(val[index]["address"].to_i)
            sub_question.merge!({ 'content'=> 
              {
                "address"=> town, 
                "detail" => val[index]["detail"],
                "postcode" => val[index]["postcode"].to_i
              }})         
          end
          
          show_answer['items'] << sub_question
        end
        answer["question_content"] << show_answer
      when QuestionTypeEnum::MATRIX_BLANK_QUESTION
        # 
        # Example:
        # show_answer = {'question_type' => 10 ,
        #     'question_type_label'=> '',
        #     'title'=>'XXXXXXXXXXX', 
        show_answer.merge!({'question_type_label'=> ''})
      when QuestionTypeEnum::CONST_SUM_QUESTION
        # 比重题
        # Example:
        # show_answer = {'question_type' => 11 ,
        #     'question_type_label'=> '比重题',
        #     'title'=>'XXXXXXXXXXX',
        #     'items' => [
        #       {
        #         'title' => 'XXXXXXXXXXX',
        #         'content' => 'XX'
        #       },
        #       ...
        #     ]
        #   }
        show_answer.merge!({'question_type_label'=> '比重题'})
        answer["question_content"] << show_answer and next if val.blank?

        show_answer['items'] = []
        question.issue['items'].each do |item|
          tmp_item = {'title'=>item['content']['text']}
          tmp_item_answer = val.select{|k,v| k.to_s==item['id'].to_s}.values.first
          tmp_item.merge!({'content' => tmp_item_answer})
          show_answer['items'] << tmp_item
        end
        if question.issue['other_item'] && question.issue['other_item']['has_other_item'].to_s=='true'
          item = question.issue['other_item']['has_other_item']
          tmp_item = {'title'=>item['content']['text']}
          tmp_item_answer = val.select{|k,v| k.to_s==item['id'].to_s}.values.first
          tmp_item.merge!({'content' => tmp_item_answer})
          show_answer['items'] << tmp_item
        end

        answer["question_content"] << show_answer
      when QuestionTypeEnum::SORT_QUESTION
        # 排序题
        # Example:
        # show_answer = {'question_type' => 12 ,
        #     'question_type_label'=> '排序题',
        #     'title'=>'XXXXXXXXXXX',
        #     'items' => [
        #       {
        #         'title' => 'XXXXXXXXXXX',
        #       },
        #       ...
        #     ]
        #   }
        show_answer.merge!({'question_type_label'=> '排序题'})
        answer["question_content"] << show_answer and next if val.blank?

        show_answer['items'] = []
        val['sort_result'].each do |id_s|
          item = question.issue['items'].select{|elem| elem['id'].to_s == id_s}[0]
          if item
            show_answer['items'] << {'title'=>item['content']['text']}
            next
          end
          if question.issue['other_item'] && question.issue['other_item']['has_other_item'].to_s=='true'
            item = question.issue['other_item']['has_other_item']
            show_answer['items'] << {'title'=>item['content']['text']} if item['id'].to_s == id_s
          end
        end

        answer["question_content"] << show_answer
      when QuestionTypeEnum::RANK_QUESTION
        # 
        # Example:
        # show_answer = {'question_type' => 13 ,
        #     'question_type_label'=> '',
        #     'title'=>'XXXXXXXXXXX',
        show_answer.merge!({'question_type_label'=> ''})
      when QuestionTypeEnum::PARAGRAPH
        # 文本段
        # Example:
        # show_answer = {'question_type' => 14 ,
        #     'question_type_label'=> '文本段',
        #     'title'=>'XXXXXXXXXXX',
        #     'content' => 'XXXXXXXXXXX'
        #   }
        show_answer.merge!({'question_type_label'=> '文本段'})
        # show_answer.merge!({"content" => val.to_s})
        answer["question_content"] << show_answer
      when QuestionTypeEnum::FILE_QUESTION  
        # 
        # Example:
        # show_answer = {'question_type' => 15 ,
        #     'question_type_label'=> '',
        #     'title'=>'XXXXXXXXXXX',
        show_answer.merge!({'question_type_label'=> ''})
      when QuestionTypeEnum::TABLE_QUESTION
        # 
        # Example:
        # show_answer = {'question_type' => 16 ,
        #     'question_type_label'=> '',
        #     'title'=>'XXXXXXXXXXX',

        show_answer.merge!({'question_type_label'=> ''})
      when QuestionTypeEnum::SCALE_QUESTION
        # 量表题
        # Example:
        # show_answer = {'question_type' =>17 ,
        #     'question_type_label'=> '量表题',
        #     'title'=>'XXXXXXXXXXX',
        #     'labels' => ["很不满意", "不满意", "满意", "很满意"]
        #     'choices' => ['aaa', 'bbb', 'ccc']
        #     'selected_labels' => ["很不满意", "不满意", "满意"]
        #   }
        show_answer.merge!({'question_type_label'=> '量表题'})
        answer["question_content"] << show_answer and next if val.blank?

        show_answer.merge!({"labels" => question.issue["labels"]})
        if question.issue["items"] 
          choices = []
          selected_labels = []
          question.issue["items"].each do |item|
            choices << item["content"]["text"]
            val.each do |v_index, v_val|
              if v_index.to_s == item['id'].to_s
                selected_labels << question.issue["labels"][v_val.to_i] if v_val.to_i >=0
                selected_labels << "不清楚" if v_val.to_i == -1
              end
            end
          end
          show_answer.merge!({"choices"=>choices})
          show_answer.merge!({"selected_labels"=> selected_labels})
        end

        answer["question_content"] << show_answer
      end 
    end
    answer
  end

  def answer_percentage
    questions = self.load_question(nil, true)
    question_number = self.survey.all_questions_id(true).length + self.random_quality_control_answer_content.length
    self.index_of(questions, true) / question_number.to_f
  end

  def append_reward_info
    self["select_reward"] = ""
    self["free_reward"] = self["rewards"].to_a.empty?
    self["rewards"].to_a.each do |rew|
      # a["select_reward"] = "" and break if a["answer_status"].to_i == 2 
      next if rew["checked"] != true
      case rew["type"].to_i
      when RewardScheme::MOBILE
        self["select_reward"] = "#{rew["amount"].to_i}元话费"
      when RewardScheme::ALIPAY
        self["select_reward"] = "#{rew["amount"].to_i}元支付宝"
      when RewardScheme::POINT 
        self["select_reward"] = "#{rew["amount"].to_i}积分"
      when RewardScheme::LOTTERY
        lottery_link = "/lotteries/#{self.id.to_s}"
        self["select_reward"] = %Q{<a class='lottery' target='_blank' href='#{lottery_link}'>抽奖机会</a>}
      when RewardScheme::JIFENBAO
        self["select_reward"] = "#{rew["amount"].to_i}集分宝"
      end
      break
    end
    self
  end

  def update_sample_attributes
    # return if no user or attributes already updated
    return false if self.user.blank? || self.sample_attributes_updated
    self.answer_content.each do |q_id, answer|
      q = BasicQuestion.find_by_id(q_id)
      next if answer.blank? || q.blank? || q.sample_attribute.blank?
      attr_value = nil
      case q.sample_attribute.type
      when DataType::STRING
        attr_value = answer if q.question_type == QuestionTypeEnum::TEXT_BLANK_QUESTION
      when DataType::ENUM
        if q.question_type == QuestionTypeEnum::CHOICE_QUESTION
          attr_value = q.sample_attribute_relation[answer["selection"][0].to_s]
        end
      when DataType::NUMBER
        attr_value = answer if q.question_type == QuestionTypeEnum::NUMBER_BLANK_QUESTION
      when DataType::NUMBER_RANGE
        if q.question_type == QuestionTypeEnum::NUMBER_BLANK_QUESTION
          attr_value = [answer, answer] if answer.present?
        elsif q.question_type == QuestionTypeEnum::CHOICE_QUESTION
          cur_attr_value = self.user.read_sample_attribute(q.sample_attribute.name)
          attr_value = q.sample_attribute_relation[answer["selection"][0].to_s]
          if attr_value.present?
            attr_value[0] = attr_value[0].blank? ? -1.0/0.0 : attr_value[0].to_f
            attr_value[1] = attr_value[1].blank? ? 1.0/0.0 : attr_value[1].to_f
          end
          attr_value = nil if Tool.range_compare(attr_value, cur_attr_value) == 1
        end
      when DataType::DATE
        attr_value = answer / 1000 if q.question_type == QuestionTypeEnum::TIME_BLANK_QUESTION
      when DataType::DATE_RANGE
        if q.question_type == QuestionTypeEnum::TIME_BLANK_QUESTION
          attr_value = [answer / 1000, answer / 1000] if answer.present?
        elsif q.question_type == QuestionTypeEnum::CHOICE_QUESTION
          cur_attr_value = self.user.read_sample_attribute(q.sample_attribute.name)
          attr_value = q.sample_attribute_relation[answer["selection"][0].to_s]
          if attr_value.present?
            attr_value[0] = attr_value[0].blank? ? -1.0/0.0 : attr_value[0] / 1000
            attr_value[1] = attr_value[1].blank? ? 1.0/0.0 : attr_value[1] / 1000
          end
          attr_value = nil if Tool.range_compare(attr_value, cur_attr_value) == 1
        end
      when DataType::ADDRESS
        if q.question_type == QuestionTypeEnum::ADDRESS_BLANK_QUESTION
          attr_value = answer["address"]
        elsif q.question_type == QuestionTypeEnum::CHOICE_QUESTION
          attr_value = q.sample_attribute_relation[answer["selection"][0].to_s]
        end
      when DataType::ARRAY
        if q.question_type == QuestionTypeEnum::CHOICE_QUESTION
          new_attr_value = []
          answer["selection"].each do |input_id|
            enum_value = q.sample_attribute_relation[input_id.to_s]
            new_attr_value << enum_value if enum_value.present?
          end
          attr_value = (self.user.read_sample_attribute(q.sample_attribute.name).to_a + new_attr_value).uniq
        end
      end
      self.user.write_sample_attribute(q.sample_attribute.name, attr_value) if attr_value.present?
    end
    self.update_attributes(sample_attributes_updated: true)
  end

  def check_matrix_answer
    result = false
    self.answer_content.each do |k, v|
      q = Question.find_by_id(k)
      next if q.nil? || q.question_type != QuestionTypeEnum::MATRIX_CHOICE_QUESTION
      next if v.nil?
      if q.issue["option_type"] == 0
        # single choice
        identical = true
        if v.present? && v.length >= 5
          (v.values[1..-1] || []).each do |e|
            identical &&= v.values[0] == e
          end
        else
          identical = false
        end
      else
        # multiple choice
        identical = true
        if (v.values[0] || []).length >= 4 || v.length >= 5
          (v.values[1..-1] || []).each do |e|
            identical &&= v.values[0] == e
          end
        else
          identical = false
        end
      end

      if identical
        result = true
        break
      end
    end
    self.update_attributes(suspected: result)
    return self.suspected
  end

  def self.check_matrix_answer
    Carnival::SURVEY.each do |sid|
      Survey.find(sid).answers.each do |a|
        # next if !a.suspected.nil?
        a.check_matrix_answer
      end
    end
  end

  def check_contradiction
    auditor = User.find_by_email('gaoyuzhen@oopsdata.com')
    case self.survey.id.to_s
    when "5384282deb0e5bbcb900002b"
      # 问卷吧嘉年华小任务（编号：XFXW-02）
      # 回答不认真，您最近一次购买以下服装是在什么时候？您选择的最近购买过。而后面的您通常购买以下服装是在什么地点？却选择没有购买过。前后矛盾。
      q1_id = "5384282deb0e5bbcb900002e"
      if self.answer_content[q1_id].present?
        q1_id_ary = ["5384282deb0e5bbcb900002f", "5384282deb0e5bbcb9000030", "5384282deb0e5bbcb9000031", "5384282deb0e5bbcb9000032", "5384282deb0e5bbcb9000033", "5384282deb0e5bbcb9000034", "5384282deb0e5bbcb9000035", "5384282deb0e5bbcb9000036", "5384282deb0e5bbcb9000037"]
        if [6063282373457212, 1332025380940685, 629956041602594, 8743666065696540, 20654034206111250].include?(self.answer_content[q1_id]["8421881148058847"][0])
          if self.answer_content[q1_id_ary[0]]["selection"].include?(26906607407257976)
            return self.review(false, auditor, "回答不认真，您最近一次购买以下服装是在什么时候？您选择的最近购买过。而后面的您通常购买以下服装是在什么地点？却选择没有购买过。前后矛盾。")
          end
        end
        if [6063282373457212, 1332025380940685, 629956041602594, 8743666065696540, 20654034206111250].include?(self.answer_content[q1_id]["5731047882234557"][0])
          if self.answer_content[q1_id_ary[1]]["selection"].include?(15333389563179084)
            return self.review(false, auditor, "回答不认真，您最近一次购买以下服装是在什么时候？您选择的最近购买过。而后面的您通常购买以下服装是在什么地点？却选择没有购买过。前后矛盾。")
          end
        end
        if [6063282373457212, 1332025380940685, 629956041602594, 8743666065696540, 20654034206111250].include?(self.answer_content[q1_id]["6920470923816009"][0])
          if self.answer_content[q1_id_ary[2]]["selection"].include?(22562795826490028)
            return self.review(false, auditor, "回答不认真，您最近一次购买以下服装是在什么时候？您选择的最近购买过。而后面的您通常购买以下服装是在什么地点？却选择没有购买过。前后矛盾。")
          end
        end
        if [6063282373457212, 1332025380940685, 629956041602594, 8743666065696540, 20654034206111250].include?(self.answer_content[q1_id]["1905180640109205"][0])
          if self.answer_content[q1_id_ary[3]]["selection"].include?(23045718616622224)
            return self.review(false, auditor, "回答不认真，您最近一次购买以下服装是在什么时候？您选择的最近购买过。而后面的您通常购买以下服装是在什么地点？却选择没有购买过。前后矛盾。")
          end
        end
        if [6063282373457212, 1332025380940685, 629956041602594, 8743666065696540, 20654034206111250].include?(self.answer_content[q1_id]["24016718891360356"][0])
          if self.answer_content[q1_id_ary[4]]["selection"].include?(15060067400644048)
            return self.review(false, auditor, "回答不认真，您最近一次购买以下服装是在什么时候？您选择的最近购买过。而后面的您通常购买以下服装是在什么地点？却选择没有购买过。前后矛盾。")
          end
        end
        if [6063282373457212, 1332025380940685, 629956041602594, 8743666065696540, 20654034206111250].include?(self.answer_content[q1_id]["18793900016606364"][0])
          if self.answer_content[q1_id_ary[5]]["selection"].include?(20929449850566080)
            return self.review(false, auditor, "回答不认真，您最近一次购买以下服装是在什么时候？您选择的最近购买过。而后面的您通常购买以下服装是在什么地点？却选择没有购买过。前后矛盾。")
          end
        end
        if [6063282373457212, 1332025380940685, 629956041602594, 8743666065696540, 20654034206111250].include?(self.answer_content[q1_id]["15971570274703724"][0])
          if self.answer_content[q1_id_ary[6]]["selection"].include?(17785995684465368)
            return self.review(false, auditor, "回答不认真，您最近一次购买以下服装是在什么时候？您选择的最近购买过。而后面的您通常购买以下服装是在什么地点？却选择没有购买过。前后矛盾。")
          end
        end
        if [6063282373457212, 1332025380940685, 629956041602594, 8743666065696540, 20654034206111250].include?(self.answer_content[q1_id]["26517003384795564"][0])
          if self.answer_content[q1_id_ary[7]]["selection"].include?(28027343098469750)
            return self.review(false, auditor, "回答不认真，您最近一次购买以下服装是在什么时候？您选择的最近购买过。而后面的您通常购买以下服装是在什么地点？却选择没有购买过。前后矛盾。")
          end
        end
        if [6063282373457212, 1332025380940685, 629956041602594, 8743666065696540, 20654034206111250].include?(self.answer_content[q1_id]["14727999294553480"][0])
          if self.answer_content[q1_id_ary[8]]["selection"].include?(18134694218623456)
            return self.review(false, auditor, "回答不认真，您最近一次购买以下服装是在什么时候？您选择的最近购买过。而后面的您通常购买以下服装是在什么地点？却选择没有购买过。前后矛盾。")
          end
        end
      end
      # 您最近一次购买以下服装，鞋子是在什么时候？您选择的最近购买过。而后面的您通常购买以下服装是在什么地点？却选择没有购买过。前后矛盾。
      q2_id = "5384282deb0e5bbcb9000041"
      if self.answer_content[q2_id].present?
        q2_id_ary = ["5384282deb0e5bbcb9000042", "5384282deb0e5bbcb9000043", "5384282deb0e5bbcb9000044", "5384282deb0e5bbcb9000045", "5384282deb0e5bbcb9000046", "5384282deb0e5bbcb9000047", "5384282deb0e5bbcb9000048", "5384282deb0e5bbcb9000049", "5384282deb0e5bbcb900004a", "5384282deb0e5bbcb900004b"]
        if [80610906142193, 537652013685443, 6080364894431893, 2088661825684050, 13443849246235992].include?(self.answer_content[q2_id]["4252329268653682"][0])
          if self.answer_content[q2_id_ary[0]]["selection"].include?(8509585111237307)
            return self.review(false, auditor, "您最近一次购买以下服装，鞋子是在什么时候？您选择的最近购买过。而后面的您通常购买以下服装是在什么地点？却选择没有购买过。前后矛盾。")
          end
        end
        if [80610906142193, 537652013685443, 6080364894431893, 2088661825684050, 13443849246235992].include?(self.answer_content[q2_id]["25166279325515350"][0])
          if self.answer_content[q2_id_ary[1]]["selection"].include?(17528728611175652)
            return self.review(false, auditor, "您最近一次购买以下服装，鞋子是在什么时候？您选择的最近购买过。而后面的您通常购买以下服装是在什么地点？却选择没有购买过。前后矛盾。")
          end
        end
        if [80610906142193, 537652013685443, 6080364894431893, 2088661825684050, 13443849246235992].include?(self.answer_content[q2_id]["12077112613499512"][0])
          if self.answer_content[q2_id_ary[2]]["selection"].include?(18826881988340904)
            return self.review(false, auditor, "您最近一次购买以下服装，鞋子是在什么时候？您选择的最近购买过。而后面的您通常购买以下服装是在什么地点？却选择没有购买过。前后矛盾。")
          end
        end
        if [80610906142193, 537652013685443, 6080364894431893, 2088661825684050, 13443849246235992].include?(self.answer_content[q2_id]["24724363208536420"][0])
          if self.answer_content[q2_id_ary[3]]["selection"].include?(15482650482064836)
            return self.review(false, auditor, "您最近一次购买以下服装，鞋子是在什么时候？您选择的最近购买过。而后面的您通常购买以下服装是在什么地点？却选择没有购买过。前后矛盾。")
          end
        end
        if [80610906142193, 537652013685443, 6080364894431893, 2088661825684050, 13443849246235992].include?(self.answer_content[q2_id]["16341843170833212"][0])
          if self.answer_content[q2_id_ary[4]]["selection"].include?(27838643820950176)
            return self.review(false, auditor, "您最近一次购买以下服装，鞋子是在什么时候？您选择的最近购买过。而后面的您通常购买以下服装是在什么地点？却选择没有购买过。前后矛盾。")
          end
        end
        if [80610906142193, 537652013685443, 6080364894431893, 2088661825684050, 13443849246235992].include?(self.answer_content[q2_id]["21065405170686920"][0])
          if self.answer_content[q2_id_ary[5]]["selection"].include?(20117934599072816)
            return self.review(false, auditor, "您最近一次购买以下服装，鞋子是在什么时候？您选择的最近购买过。而后面的您通常购买以下服装是在什么地点？却选择没有购买过。前后矛盾。")
          end
        end
        if [80610906142193, 537652013685443, 6080364894431893, 2088661825684050, 13443849246235992].include?(self.answer_content[q2_id]["27254975234412044"][0])
          if self.answer_content[q2_id_ary[6]]["selection"].include?(24303521636451948)
            return self.review(false, auditor, "您最近一次购买以下服装，鞋子是在什么时候？您选择的最近购买过。而后面的您通常购买以下服装是在什么地点？却选择没有购买过。前后矛盾。")
          end
        end
        if [80610906142193, 537652013685443, 6080364894431893, 2088661825684050, 13443849246235992].include?(self.answer_content[q2_id]["25102518150836624"][0])
          if self.answer_content[q2_id_ary[7]]["selection"].include?(16530286885401964)
            return self.review(false, auditor, "您最近一次购买以下服装，鞋子是在什么时候？您选择的最近购买过。而后面的您通常购买以下服装是在什么地点？却选择没有购买过。前后矛盾。")
          end
        end
        if [80610906142193, 537652013685443, 6080364894431893, 2088661825684050, 13443849246235992].include?(self.answer_content[q2_id]["19494109406389700"][0])
          if self.answer_content[q2_id_ary[8]]["selection"].include?(18917522031438016)
            return self.review(false, auditor, "您最近一次购买以下服装，鞋子是在什么时候？您选择的最近购买过。而后面的您通常购买以下服装是在什么地点？却选择没有购买过。前后矛盾。")
          end
        end
        if [80610906142193, 537652013685443, 6080364894431893, 2088661825684050, 13443849246235992].include?(self.answer_content[q2_id]["13331135805949980"][0])
          if self.answer_content[q2_id_ary[9]]["selection"].include?(15332060997953048)
            return self.review(false, auditor, "您最近一次购买以下服装，鞋子是在什么时候？您选择的最近购买过。而后面的您通常购买以下服装是在什么地点？却选择没有购买过。前后矛盾。")
          end
        end
      end
      # 您最近一次购买以下配饰是在什么时候？您选择的最近购买过。您通常购买一下配饰是在什么地点？却选择没有购买过。前后矛盾。
      q3_id = "5384282deb0e5bbcb9000058"
      if self.answer_content[q3_id].present?
        q3_id_ary = ["5384282deb0e5bbcb9000059", "5384282deb0e5bbcb900005a", "5384282deb0e5bbcb900005b", "5384282deb0e5bbcb900005c", "5384282deb0e5bbcb900005d", "5384282deb0e5bbcb900005e", "5384282deb0e5bbcb900005f", "5384282deb0e5bbcb9000060", "5384282deb0e5bbcb9000061", "5384282deb0e5bbcb9000062", "5384282deb0e5bbcb9000063"]
        if [5511498787937847, 3260314383344951, 6758167448164534, 6902359150061489, 13194501943255804].include?(self.answer_content[q3_id]["5774153198153655"][0])
          if self.answer_content[q3_id_ary[0]]["selection"].include?(19328245926638090)
            return self.review(false, auditor, "您最近一次购买以下配饰是在什么时候？您选择的最近购买过。您通常购买一下配饰是在什么地点？却选择没有购买过。前后矛盾。")
          end
        end
        if [5511498787937847, 3260314383344951, 6758167448164534, 6902359150061489, 13194501943255804].include?(self.answer_content[q3_id]["6935449779139548"][0])
          if self.answer_content[q3_id_ary[1]]["selection"].include?(25297077345676840)
            return self.review(false, auditor, "您最近一次购买以下配饰是在什么时候？您选择的最近购买过。您通常购买一下配饰是在什么地点？却选择没有购买过。前后矛盾。")
          end
        end
        if [5511498787937847, 3260314383344951, 6758167448164534, 6902359150061489, 13194501943255804].include?(self.answer_content[q3_id]["6595512487294154"][0])
          if self.answer_content[q3_id_ary[2]]["selection"].include?(22827636179093320)
            return self.review(false, auditor, "您最近一次购买以下配饰是在什么时候？您选择的最近购买过。您通常购买一下配饰是在什么地点？却选择没有购买过。前后矛盾。")
          end
        end
        if [5511498787937847, 3260314383344951, 6758167448164534, 6902359150061489, 13194501943255804].include?(self.answer_content[q3_id]["4574881044486772"][0])
          if self.answer_content[q3_id_ary[3]]["selection"].include?(30228617297101056)
            return self.review(false, auditor, "您最近一次购买以下配饰是在什么时候？您选择的最近购买过。您通常购买一下配饰是在什么地点？却选择没有购买过。前后矛盾。")
          end
        end
        if [5511498787937847, 3260314383344951, 6758167448164534, 6902359150061489, 13194501943255804].include?(self.answer_content[q3_id]["16570173053353908"][0])
          if self.answer_content[q3_id_ary[4]]["selection"].include?(21210143022345256)
            return self.review(false, auditor, "您最近一次购买以下配饰是在什么时候？您选择的最近购买过。您通常购买一下配饰是在什么地点？却选择没有购买过。前后矛盾。")
          end
        end
        if [5511498787937847, 3260314383344951, 6758167448164534, 6902359150061489, 13194501943255804].include?(self.answer_content[q3_id]["22552797757837810"][0])
          if self.answer_content[q3_id_ary[5]]["selection"].include?(23225210126153116)
            return self.review(false, auditor, "您最近一次购买以下配饰是在什么时候？您选择的最近购买过。您通常购买一下配饰是在什么地点？却选择没有购买过。前后矛盾。")
          end
        end
        if [5511498787937847, 3260314383344951, 6758167448164534, 6902359150061489, 13194501943255804].include?(self.answer_content[q3_id]["23662811227425824"][0])
          if self.answer_content[q3_id_ary[6]]["selection"].include?(18883132176625290)
            return self.review(false, auditor, "您最近一次购买以下配饰是在什么时候？您选择的最近购买过。您通常购买一下配饰是在什么地点？却选择没有购买过。前后矛盾。")
          end
        end
        if [5511498787937847, 3260314383344951, 6758167448164534, 6902359150061489, 13194501943255804].include?(self.answer_content[q3_id]["21751476652737612"][0])
          if self.answer_content[q3_id_ary[7]]["selection"].include?(20678020665600784)
            return self.review(false, auditor, "您最近一次购买以下配饰是在什么时候？您选择的最近购买过。您通常购买一下配饰是在什么地点？却选择没有购买过。前后矛盾。")
          end
        end
        if [5511498787937847, 3260314383344951, 6758167448164534, 6902359150061489, 13194501943255804].include?(self.answer_content[q3_id]["21000437332134600"][0])
          if self.answer_content[q3_id_ary[8]]["selection"].include?(20111189078278720)
            return self.review(false, auditor, "您最近一次购买以下配饰是在什么时候？您选择的最近购买过。您通常购买一下配饰是在什么地点？却选择没有购买过。前后矛盾。")
          end
        end
        if [5511498787937847, 3260314383344951, 6758167448164534, 6902359150061489, 13194501943255804].include?(self.answer_content[q3_id]["19265310329668136"][0])
          if self.answer_content[q3_id_ary[9]]["selection"].include?(22638846609036320)
            return self.review(false, auditor, "您最近一次购买以下配饰是在什么时候？您选择的最近购买过。您通常购买一下配饰是在什么地点？却选择没有购买过。前后矛盾。")
          end
        end
        if [5511498787937847, 3260314383344951, 6758167448164534, 6902359150061489, 13194501943255804].include?(self.answer_content[q3_id]["21050428569599900"][0])
          if self.answer_content[q3_id_ary[10]]["selection"].include?(27501447805005100)
            return self.review(false, auditor, "您最近一次购买以下配饰是在什么时候？您选择的最近购买过。您通常购买一下配饰是在什么地点？却选择没有购买过。前后矛盾。")
          end
        end
      end
    when "53843187eb0e5b2ac8000037"
      # 问卷吧嘉年华小任务（编号：XFXW-06）
      q1_id = "53843187eb0e5b2ac800003b"
      # 您在回答在不影响家庭稳定的情况下，我不反对婚外恋的问题时，选择了赞同；在回答我认为婚后应该对伴侣忠诚的问题时，选择了赞同，前后矛盾，没有认真答题。
      if self.answer_content[q1_id].present?
        if [2266010792463603, 5067004245540575].include?((self.answer_content[q1_id]["5659440666829353"] || [])[0]) && [2266010792463603, 5067004245540575].include?((self.answer_content[q1_id]["18612246297257348"] || [])[0])
          return self.review(false, auditor, "您在回答在不影响家庭稳定的情况下，我不反对婚外恋的问题时，选择了赞同；在回答我认为婚后应该对伴侣忠诚的问题时，选择了赞同，前后矛盾，没有认真答题。")
        end
      end
      # 您在回答在不影响家庭稳定的情况下，我不反对婚外恋的问题时，选择了不赞同；在回答我认为婚后应该对伴侣忠诚的问题时，选择了不赞同，前后矛盾，没有认真答题。
      if self.answer_content[q1_id].present?
        if [1270715460665074, 7800577250270601].include?((self.answer_content[q1_id]["5659440666829353"] || [])[0]) && [1270715460665074, 7800577250270601].include?((self.answer_content[q1_id]["18612246297257348"] || [])[0])
          return self.review(false, auditor, "您在回答在不影响家庭稳定的情况下，我不反对婚外恋的问题时，选择了不赞同；在回答我认为婚后应该对伴侣忠诚的问题时，选择了不赞同，前后矛盾，没有认真答题。")
        end
      end
      # 您在回答人的一生可以有多个性伙伴的问题时，选择了赞同；在回答我认为婚后应该对伴侣忠诚的问题时，选择了赞同，前后矛盾，没有认真答题。
      if self.answer_content[q1_id].present?
        if [2266010792463603, 5067004245540575].include?((self.answer_content[q1_id]["12005902279563464"] || [])[0]) && [2266010792463603, 5067004245540575].include?((self.answer_content[q1_id]["18612246297257348"] || [])[0])
          return self.review(false, auditor, "您在回答人的一生可以有多个性伙伴的问题时，选择了赞同；在回答我认为婚后应该对伴侣忠诚的问题时，选择了赞同，前后矛盾，没有认真答题。")
        end
      end
      # 您在回答人的一生可以有多个性伙伴的问题时，选择了不赞同；在回答我认为婚后应该对伴侣忠诚的问题时，选择了不赞同，前后矛盾，没有认真答题。
      if self.answer_content[q1_id].present?
        if [1270715460665074, 7800577250270601].include?((self.answer_content[q1_id]["12005902279563464"] || [])[0]) && [1270715460665074, 7800577250270601].include?((self.answer_content[q1_id]["18612246297257348"] || [])[0])
          return self.review(false, auditor, "您在回答人的一生可以有多个性伙伴的问题时，选择了不赞同；在回答我认为婚后应该对伴侣忠诚的问题时，选择了不赞同，前后矛盾，没有认真答题。")
        end
      end
      q2_id = "53843187eb0e5b2ac800003d"
      # 您在回答父母为成年子女买房买车，是理所当然的问题时，选择了赞同；您在回答子女不应该啃老的问题时，选择了赞同，前后矛盾，没有认真答题。
      if self.answer_content[q2_id].present?
        if [3729430513998543, 4454254694219727].include?((self.answer_content[q2_id]["483117460548432"] || [])[0]) && [3729430513998543, 4454254694219727].include?((self.answer_content[q2_id]["15834195234798144"] || [])[0])
          return self.review(false, auditor, "您在回答父母为成年子女买房买车，是理所当然的问题时，选择了赞同；您在回答子女不应该啃老的问题时，选择了赞同，前后矛盾，没有认真答题。")
        end
      end
      # 您在回答父母为成年子女买房买车，是理所当然的问题时，选择了不赞同；您在回答子女不应该啃老的问题时，选择了不赞同，前后矛盾，没有认真答题。
      if self.answer_content[q2_id].present?
        if [5206008404796127, 18666950161695570].include?((self.answer_content[q2_id]["483117460548432"] || [])[0]) && [5206008404796127, 18666950161695570].include?((self.answer_content[q2_id]["15834195234798144"] || [])[0])
          return self.review(false, auditor, "您在回答父母为成年子女买房买车，是理所当然的问题时，选择了不赞同；您在回答子女不应该啃老的问题时，选择了不赞同，前后矛盾，没有认真答题。")
        end
      end
      q3_id = "53843187eb0e5b2ac800003e"
      # 您在回答不介意男性女性谁更强势，只要互相满意就行的问题时，选择了赞同；您在回答我不能接受男女关系中女性占主导的问题时，选择了赞同，前后矛盾，没有认真答题。
      if self.answer_content[q3_id].present?
        if [9469874432835554, 7681413586680518].include?((self.answer_content[q3_id]["9185048434343078"] || [])[0]) && [9469874432835554, 7681413586680518].include?((self.answer_content[q3_id]["20199379702567652"] || [])[0])
          return self.review(false, auditor, "您在回答不介意男性女性谁更强势，只要互相满意就行的问题时，选择了赞同；您在回答我不能接受男女关系中女性占主导的问题时，选择了赞同，前后矛盾，没有认真答题。")
        end
      end
      # 您在回答不介意男性女性谁更强势，只要互相满意就行的问题时，选择了不赞同；您在回答我不能接受男女关系中女性占主导的问题时，选择了不赞同，前后矛盾，没有认真答题。
      if self.answer_content[q3_id].present?
        if [8319240065055097, 5658047513723913].include?((self.answer_content[q3_id]["9185048434343078"] || [])[0]) && [8319240065055097, 5658047513723913].include?((self.answer_content[q3_id]["20199379702567652"] || [])[0])
          return self.review(false, auditor, "您在回答不介意男性女性谁更强势，只要互相满意就行的问题时，选择了不赞同；您在回答我不能接受男女关系中女性占主导的问题时，选择了不赞同，前后矛盾，没有认真答题。")
        end
      end
      q4_id = "53843187eb0e5b2ac800003f"
      # 您在回答我总是能按时吃饭的问题时，选择了赞同；您在回答我常常因为一些原因耽误了吃饭睡觉的时间的问题时，选择了赞同，前后矛盾，没有认真答题。
      if self.answer_content[q4_id].present?
        if [4247775521710277, 3748205862205147].include?((self.answer_content[q4_id]["2926838308338995"] || [])[0]) && [4247775521710277, 3748205862205147].include?((self.answer_content[q4_id]["22460966436741384"] || [])[0])
          return self.review(false, auditor, "您在回答我总是能按时吃饭的问题时，选择了赞同；您在回答我常常因为一些原因耽误了吃饭睡觉的时间的问题时，选择了赞同，前后矛盾，没有认真答题。")
        end
      end
      # 您在回答我总是能按时吃饭的问题时，选择了不赞同；您在回答我常常因为一些原因耽误了吃饭睡觉的时间的问题时，选择了不赞同，前后矛盾，没有认真答题。
      if self.answer_content[q4_id].present?
        if [9784563136934096, 14712701360876656].include?((self.answer_content[q4_id]["2926838308338995"] || [])[0]) && [9784563136934096, 14712701360876656].include?((self.answer_content[q4_id]["22460966436741384"] || [])[0])
          return self.review(false, auditor, "您在回答我总是能按时吃饭的问题时，选择了不赞同；您在回答我常常因为一些原因耽误了吃饭睡觉的时间的问题时，选择了不赞同，前后矛盾，没有认真答题。")
        end
      end
      q5_id = "53843187eb0e5b2ac8000043"
      # 您在回答我觉得周围的人比较尊重、欣赏我的问题时，选择了赞同；您在回答我觉得同事和老板并不赏识我的问题时，选择了赞同，前后矛盾，没有认真答题。
      if self.answer_content[q5_id].present?
        if [4872314033006373, 542422466260607].include?((self.answer_content[q5_id]["11662298124656860"] || [])[0]) && [4872314033006373, 542422466260607].include?((self.answer_content[q5_id]["23248677102980936"] || [])[0])
          return self.review(false, auditor, "您在回答我觉得周围的人比较尊重、欣赏我的问题时，选择了赞同；您在回答我觉得同事和老板并不赏识我的问题时，选择了赞同，前后矛盾，没有认真答题。")
        end
      end
      # 您在回答我觉得周围的人比较尊重、欣赏我的问题时，选择了不赞同；您在回答我觉得同事和老板并不赏识我的问题时，选择了不赞同，前后矛盾，没有认真答题。
      if self.answer_content[q5_id].present?
        if [1750861104257711, 13990643886299348].include?((self.answer_content[q5_id]["11662298124656860"] || [])[0]) && [1750861104257711, 13990643886299348].include?((self.answer_content[q5_id]["23248677102980936"] || [])[0])
          return self.review(false, auditor, "您在回答我觉得周围的人比较尊重、欣赏我的问题时，选择了不赞同；您在回答我觉得同事和老板并不赏识我的问题时，选择了不赞同，前后矛盾，没有认真答题。")
        end
      end
      q6_id = "5387f6e7eb0e5b63c8000084"
      # 您在回答为了提高生活品质，我可以接受贷款和借债的问题时，选择了赞同；您在回答哪怕为了改善生活，我也不愿意欠别人钱的问题时，选择了赞同，前后矛盾，没有认真答题。
      if self.answer_content[q6_id].present?
        if [1118561990446328, 1135563994747466].include?((self.answer_content[q6_id]["7556701418003352"] || [])[0]) && [1118561990446328, 1135563994747466].include?((self.answer_content[q6_id]["15396301937919656"] || [])[0])
          return self.review(false, auditor, "您在回答为了提高生活品质，我可以接受贷款和借债的问题时，选择了赞同；您在回答哪怕为了改善生活，我也不愿意欠别人钱的问题时，选择了赞同，前后矛盾，没有认真答题。")
        end
      end
      # 您在回答为了提高生活品质，我可以接受贷款和借债的问题时，选择了不赞同；您在回答哪怕为了改善生活，我也不愿意欠别人钱的问题时，选择了不赞同，前后矛盾，没有认真答题。
      if self.answer_content[q6_id].present?
        if [6282167280981283, 19479556202586436].include?((self.answer_content[q6_id]["7556701418003352"] || [])[0]) && [6282167280981283, 19479556202586436].include?((self.answer_content[q6_id]["15396301937919656"] || [])[0])
          return self.review(false, auditor, "您在回答为了提高生活品质，我可以接受贷款和借债的问题时，选择了赞同；您在回答哪怕为了改善生活，我也不愿意欠别人钱的问题时，选择了赞同，前后矛盾，没有认真答题。")
        end
      end
      q7_id = "5387f6f7eb0e5b63c8000085"
      # 您在回答我经常观察其他人是否使用名牌商品的问题时，选择了赞同；您在回答我不会注意到周围人是否在使用名牌商品的问题时，选择了赞同，前后矛盾，没有认真答题。
      if self.answer_content[q7_id].present?
        if [310777727905778, 9074270701623456].include?((self.answer_content[q7_id]["923178067319331"] || [])[0]) && [310777727905778, 9074270701623456].include?((self.answer_content[q7_id]["9126189132884300"] || [])[0])
          return self.review(false, auditor, "您在回答我经常观察其他人是否使用名牌商品的问题时，选择了赞同；您在回答我不会注意到周围人是否在使用名牌商品的问题时，选择了赞同，前后矛盾，没有认真答题。")
        end
      end
      # 您在回答我经常观察其他人是否使用名牌商品的问题时，选择了不赞同；您在回答我不会注意到周围人是否在使用名牌商品的问题时，选择了不赞同，前后矛盾，没有认真答题。
      if self.answer_content[q7_id].present?
        if [7223399211883869, 19110985263434800].include?((self.answer_content[q7_id]["923178067319331"] || [])[0]) && [7223399211883869, 19110985263434800].include?((self.answer_content[q7_id]["9126189132884300"] || [])[0])
          return self.review(false, auditor, "您在回答我经常观察其他人是否使用名牌商品的问题时，选择了不赞同；您在回答我不会注意到周围人是否在使用名牌商品的问题时，选择了不赞同，前后矛盾，没有认真答题。")
        end
      end
      q8_id = "5387f6faeb0e5b63c8000086"
      # 您在回答人和人之间越来越平等了，特权现象减少了的问题时，选择了赞同；您在回答社会不公平越来越明显，很多人有特权的问题时，选择了赞同，前后矛盾，没有认真答题。
      if self.answer_content[q8_id].present?
        if [6570602281113133, 1869451695589552].include?((self.answer_content[q8_id]["23743809319774560"] || [])[0]) && [6570602281113133, 1869451695589552].include?((self.answer_content[q8_id]["16998110318772216"] || [])[0])
          return self.review(false, auditor, "您在回答人和人之间越来越平等了，特权现象减少了的问题时，选择了赞同；您在回答社会不公平越来越明显，很多人有特权的问题时，选择了赞同，前后矛盾，没有认真答题。")
        end
      end
      # 您在回答人和人之间越来越平等了，特权现象减少了的问题时，选择了不赞同；您在回答社会不公平越来越明显，很多人有特权的问题时，选择了不赞同，前后矛盾，没有认真答题。
      if self.answer_content[q8_id].present?
        if [8303131721894165, 14237650258208604].include?((self.answer_content[q8_id]["23743809319774560"] || [])[0]) && [8303131721894165, 14237650258208604].include?((self.answer_content[q8_id]["16998110318772216"] || [])[0])
          return self.review(false, auditor, "您在回答人和人之间越来越平等了，特权现象减少了的问题时，选择了不赞同；您在回答社会不公平越来越明显，很多人有特权的问题时，选择了不赞同，前后矛盾，没有认真答题。")
        end
      end
      q9_id = "5387f723eb0e5b63c8000087"
      # 您在回答即使花更多一些钱我也愿意食用绿色食品的问题时，选择了赞同；您在回答没必要为生态农产品多支付费用的问题时，选择了赞同，前后矛盾，没有认真答题。
      if self.answer_content[q9_id].present?
        if [9736586578537008, 6278687095031692].include?((self.answer_content[q9_id]["9599674978450954"] || [])[0]) && [9736586578537008, 6278687095031692].include?((self.answer_content[q9_id]["27227119990395556"] || [])[0])
          return self.review(false, auditor, "您在回答即使花更多一些钱我也愿意食用绿色食品的问题时，选择了赞同；您在回答没必要为生态农产品多支付费用的问题时，选择了赞同，前后矛盾，没有认真答题。")
        end
      end
      # 您在回答即使花更多一些钱我也愿意食用绿色食品的问题时，选择了不赞同；您在回答没必要为生态农产品多支付费用的问题时，选择了不赞同，前后矛盾，没有认真答题。
      if self.answer_content[q9_id].present?
        if [8486791375483583, 20541360557767216].include?((self.answer_content[q9_id]["9599674978450954"] || [])[0]) && [8486791375483583, 20541360557767216].include?((self.answer_content[q9_id]["27227119990395556"] || [])[0])
          return self.review(false, auditor, "您在回答即使花更多一些钱我也愿意食用绿色食品的问题时，选择了不赞同；您在回答没必要为生态农产品多支付费用的问题时，选择了不赞同，前后矛盾，没有认真答题。")
        end
      end
      q10_id = "5387f734eb0e5b63c800008a"
      # 您在回答与西方的节日相比较,我更喜欢过传统节日的问题时，选择了赞同；您在回答我更喜欢过西方节日的问题时，选择了赞同，前后矛盾，没有认真答题。
      if self.answer_content[q10_id].present?
        if [1805661974650164, 1975222385094150].include?((self.answer_content[q10_id]["805121409891742"] || [])[0]) && [1805661974650164, 1975222385094150].include?((self.answer_content[q10_id]["15621327604883530"] || [])[0])
          return self.review(false, auditor, "您在回答与西方的节日相比较,我更喜欢过传统节日的问题时，选择了赞同；您在回答我更喜欢过西方节日的问题时，选择了赞同，前后矛盾，没有认真答题。")
        end
      end
      # 您在回答与西方的节日相比较,我更喜欢过传统节日的问题时，选择了不赞同；您在回答我更喜欢过西方节日的问题时，选择了不赞同，前后矛盾，没有认真答题。
      if self.answer_content[q10_id].present?
        if [3928553455608006, 23824163601042388].include?((self.answer_content[q10_id]["805121409891742"] || [])[0]) && [3928553455608006, 23824163601042388].include?((self.answer_content[q10_id]["15621327604883530"] || [])[0])
          return self.review(false, auditor, "您在回答与西方的节日相比较,我更喜欢过传统节日的问题时，选择了不赞同；您在回答我更喜欢过西方节日的问题时，选择了不赞同，前后矛盾，没有认真答题。")
        end
      end
    when "5385982aeb0e5b7282000022"
      # 问卷吧嘉年华小任务（编号：XFXW-05）
      # 您平时多长时间使用一次化妆水?
      # 选择“从来不用”，拒绝。
      q1_id = "5385982beb0e5b728200003a"
      if self.answer_content[q1_id].present? && self.answer_content[q1_id]["selection"].include?(18626607499360290)
        return self.review(false, auditor, "您在回答使用下列哪些化妆品的问题时，选择了化妆水；在回答平时多长时间使用一次化妆水的问题时，选择了从来不用，前后矛盾，没有认真答题。")
      end
      # 您平时多长时间使用一次保湿产品?
      # 选择“从来不用”，拒绝。
      q2_id = "5385982beb0e5b728200003b"
      if self.answer_content[q2_id].present? && self.answer_content[q2_id]["selection"].include?(20117377351336600)
        return self.review(false, auditor, "您在回答使用下列哪些化妆品的问题时，选择了保湿产品；在回答平时多长时间使用一次保湿产品的问题时，选择了从来不用，前后矛盾，没有认真答题。")
      end
      # 您平时多长时间使用一次美白产品?
      # 选择“从来不用”，拒绝。
      q3_id = "5385982beb0e5b728200003c"
      if self.answer_content[q3_id].present? && self.answer_content[q3_id]["selection"].include?(24183166894457330)
        return self.review(false, auditor, "您在回答使用下列哪些化妆品的问题时，选择了美白产品；在回答平时多长时间使用一次美白产品的问题时，选择了从来不用，前后矛盾，没有认真答题。")
      end
      # 您平时多长时间使用一次抗皱产品?
      # 选择“从来不用”，拒绝。
      q4_id = "5385982beb0e5b728200003d"
      if self.answer_content[q4_id].present? && self.answer_content[q4_id]["selection"].include?(17600101280371876)
        return self.review(false, auditor, "您在回答使用下列哪些化妆品的问题时，选择了抗皱产品；在回答平时多长时间使用一次抗皱产品的问题时，选择了从来不用，前后矛盾，没有认真答题。")
      end
      # 您平时多长时间使用一次防晒产品?
      # 选择“从来不用”，拒绝。
      q5_id = "5385982beb0e5b728200003e"
      if self.answer_content[q5_id].present? && self.answer_content[q5_id]["selection"].include?(24071942529544176)
        return self.review(false, auditor, "您在回答使用下列哪些化妆品的问题时，选择了防晒产品；在回答平时多长时间使用一次防晒产品的问题时，选择了从来不用，前后矛盾，没有认真答题。")
      end
      # 您平时多长时间使用一次祛斑产品?
      # 选择“从来不用”，拒绝。
      q6_id = "5385982beb0e5b728200003f"
      if self.answer_content[q6_id].present? && self.answer_content[q6_id]["selection"].include?(13778233929924768)
        return self.review(false, auditor, "您在回答使用下列哪些化妆品的问题时，选择了祛斑产品；在回答平时多长时间使用一次祛斑产品的问题时，选择了从来不用，前后矛盾，没有认真答题。")
      end
      # 您平时多长时间使用一次祛痘产品?
      # 选择“从来不用”，拒绝。
      q7_id = "5385982beb0e5b7282000040"
      if self.answer_content[q7_id].present? && self.answer_content[q7_id]["selection"].include?(31701187658068960)
        return self.review(false, auditor, "您在回答使用下列哪些化妆品的问题时，选择了祛痘产品；在回答平时多长时间使用一次祛痘产品的问题时，选择了从来不用，前后矛盾，没有认真答题。")
      end
      # 您平时多长时间使用一次眼部护理产品?
      # 选择“从来不用”，拒绝。
      q8_id = "5385982beb0e5b7282000041"
      if self.answer_content[q8_id].present? && self.answer_content[q8_id]["selection"].include?(9819392651748270)
        return self.review(false, auditor, "您在回答使用下列哪些化妆品的问题时，选择了眼部护理产品；在回答平时多长时间使用一次眼部护理产品的问题时，选择了从来不用，前后矛盾，没有认真答题。")
      end
      # 如果第16题的子问题里选择了“不做此类护理”，那么15题对应子问题里选择除了“一个月也没有一次”外的5个选项中的任意一个选项，都拒绝，每个子问题都是如此。
      q9_id = "5385982beb0e5b7282000046"
      q10_id = "5385982beb0e5b7282000047"
      if self.answer_content[q9_id].present? && self.answer_content[q10_id].present?
        q9 = Question.find(q9_id)
        q10 = Question.find(q10_id)
        q9.issue["rows"].each_with_index do |r, index|
          q10_r_id = q10.issue["rows"][index]["id"].to_s
          if [5042842124097239, 4222621758003774, 6018777364637514, 3659747314302127, 20778639463058204].include?(self.answer_content[q9_id][r["id"].to_s][0]) && self.answer_content[q10_id][q10_r_id].include?(14268191503939008)
            return self.review(false, auditor, "您在回答做美容美发美体护理的频次的问题时，选择的时间较短，在一个月以内；在回答做美容美发美体护理的地点时，选择了不做此类护理，前后矛盾，没有认真答题。")
          end
        end
      end
    when "53842d30eb0e5bb228000008"
      # 问卷吧嘉年华小任务（编号：XFXW-04）
      # B2.您或您家未来半年内打算购买以下哪些IT数码产品？
      # B3.您或您家未来半年内不会购买以下哪些IT数码产品？
      # B2 B3选项都一样
      # 拒绝条件：相同选项的拒绝（例如B1选手机B2选手机）
      q1_id = "53842d30eb0e5bb228000032"
      q2_id = "53842d30eb0e5bb228000033"
      if self.answer_content[q1_id].present? && self.answer_content[q2_id].present?
        q1_items = Question.find(q1_id).issue["items"].map { |e| e["id"] }
        q2_items = Question.find(q2_id).issue["items"].map { |e| e["id"] }
        q1_a_index = self.answer_content[q1_id]["selection"].map { |e| q1_items.index(e) }
        q2_a_index = self.answer_content[q2_id]["selection"].map { |e| q2_items.index(e) }
        if (q1_a_index & q2_a_index).present?
          return self.review(false, auditor, "回答不认真。问题:您或您家未来半年内打算购买和您或您家未来半年内不会购买的IT数码产品,您的选择是一样的,前后矛盾。")
        end
      end

      # B12. 未来半年内您家打算购买以下哪些家用电器？
      # B13.未来半年内您家不会购买以下哪些家用电器？
      # B12.B13选项都一样
      # 拒绝条件：相同选项的拒绝
      q3_id = "53842d30eb0e5bb22800003d"
      q4_id = "53842d30eb0e5bb22800003e"
      if self.answer_content[q3_id].present? && self.answer_content[q4_id].present?
        q3_items = Question.find(q3_id).issue["items"].map { |e| e["id"] }
        q4_items = Question.find(q4_id).issue["items"].map { |e| e["id"] }
        q3_a_index = self.answer_content[q3_id]["selection"].map { |e| q3_items.index(e) }
        q4_a_index = self.answer_content[q4_id]["selection"].map { |e| q4_items.index(e) }
        if (q3_a_index & q4_a_index).present?
          return self.review(false, auditor, "回答不认真。未来半年内您家打算购买和未来半年内您家不会购买的家用电器,您的选择是一样的,前后矛盾。")
        end
      end

      # B15.您或您家未来半年内打算购买以下哪些电子电器产品？
      # B16.未来半年内您家不会购买以下哪些电子电器产品？
      # B15.B16选项都一样
      # 拒绝条件：相同选项的拒绝
      q5_id = "53842d31eb0e5bb228000041"
      q6_id = "53842d31eb0e5bb228000042"
      if self.answer_content[q5_id].present? && self.answer_content[q6_id].present?
        q5_items = Question.find(q5_id).issue["items"].map { |e| e["id"] }
        q6_items = Question.find(q6_id).issue["items"].map { |e| e["id"] }
        q5_a_index = self.answer_content[q5_id]["selection"].map { |e| q5_items.index(e) }
        q6_a_index = self.answer_content[q6_id]["selection"].map { |e| q6_items.index(e) }
        if (q5_a_index & q6_a_index).present?
          return self.review(false, auditor, "回答不认真。您或您家未来半年内打算购买和您或您家未来半年内不会购买的电子产品,您的选择是一样的,前后矛盾。")
        end
      end
    when "53868990eb0e5ba257000025"
      # 问卷吧嘉年华小任务（编号：GGJC）
      # S3.您如何看待电影中出现的品牌:
      q1_id = "53868990eb0e5ba257000029"
      # 1. 电影中出现的品牌与情节融合较好，没有太强的推销味，给人比较舒服的感觉选择非常赞同/比较赞同、电影中出现的品牌严重干扰了我欣赏电影选择非常赞同/比较赞同，前后矛盾。
      if self.answer_content[q1_id].present?
        if [4719013619515551, 888151996077422].include?((self.answer_content[q1_id]["9950100555975270"] || [])[0]) && [4719013619515551, 888151996077422].include?((self.answer_content[q1_id]["25148841093763560"] || [])[0])
          return self.review(false, auditor, "问题电影中出现的品牌与情节融合较好，没有太强的推销味，给人比较舒服的感觉您选择了非常赞同/比较赞同，后面问题：电影中出现的品牌严重干扰了我欣赏电影您选择了非常赞同/比较赞同，前后矛盾。")
        end
      end
      # 2. 电影中出现的品牌与情节融合较好，没有太强的推销味，给人比较舒服的感觉选择比较不赞同/非常不赞同、电影中出现的品牌严重干扰了我欣赏电影选择比较不赞同/非常不赞同就拒绝
      if self.answer_content[q1_id].present?
        if [2126770962836918, 22245643131364320].include?((self.answer_content[q1_id]["9950100555975270"] || [])[0]) && [2126770962836918, 22245643131364320].include?((self.answer_content[q1_id]["25148841093763560"] || [])[0])
          return self.review(false, auditor, "问题电影中出现的品牌与情节融合较好，没有太强的推销味，给人比较舒服的感觉您选择了比较不赞同/非常不赞同，后面问题：电影中出现的品牌严重干扰了我欣赏电影您选择了比较不赞同/非常不赞同，前后矛盾。")
        end
      end
      # 3. 矩阵题全部选择一般的也拒绝。
      normal = true
      self.answer_content[q1_id].each do |k, v|
        normal = normal && (v[0] == 105583791418363)
      end
      if self.answer_content[q1_id].present? && normal
        return self.review(false, auditor, "回答不认真，没有认真查看题目进行作答，系统检测到很多答案数据都是一样的，数据不真实。")
      end
      # A6.您同意以下有关影院播放广告的说法吗？
      q2_id = "53868990eb0e5ba25700002f"
      # 1. 我比较信任电影院播放的广告选择比较赞同/非常赞同、我不太信任影院播放的广告选择比较赞同/非常赞同拒绝
      if self.answer_content[q2_id].present?
        if [8317214631174188, 8484036182589157].include?((self.answer_content[q2_id]["19832762675086484"] || [])[0]) && [8317214631174188, 8484036182589157].include?((self.answer_content[q2_id]["21647195410953130"] || [])[0])
          return self.review(false, auditor, "问题我比较信任电影院播放的广告您选择了比较赞同/非常赞同，后面问题：我不太信任影院播放的广告您选择了比较赞同/非常赞同，前后矛盾。")
        end
      end
      # 2. 我比较信任电影院播放的广告选择比较不赞同/非常不赞同、我不太信任影院播放的广告选择比较不赞同/非常不赞同拒绝
      if self.answer_content[q2_id].present?
        if [6436964890405481, 6436964890405481].include?((self.answer_content[q2_id]["19832762675086484"] || [])[0]) && [6436964890405481, 6436964890405481].include?((self.answer_content[q2_id]["21647195410953130"] || [])[0])
          return self.review(false, auditor, "问题我比较信任电影院播放的广告您选择了比较不赞同/非常不赞同，后面问题：我不太信任影院播放的广告您选择了比较不赞同/非常不赞同，前后矛盾。")
        end
      end
      # 3. 矩阵题全部选择一般的也拒绝
      normal = true
      self.answer_content[q2_id].each do |k, v|
        normal = normal && (v[0] == 1024978516797060)
      end
      if self.answer_content[q2_id].present? && normal
        return self.review(false, auditor, "回答不认真，没有认真查看题目进行作答，系统检测到很多答案数据都是一样的，数据不真实。")
      end
      # B5. 您同意以下有关网络（笔记本电脑/台式机）电影插播广告的说法吗？
      q3_id = "53868990eb0e5ba257000035"
      # 1. 与其他广告相比，我更喜欢网络电影插播的广告选择比较赞同/非常赞同、我非常讨厌网络电影中插播广告选择比较赞同/非常赞同拒绝
      if self.answer_content[q3_id].present?
        if [9062626154289426, 6143316956767755].include?((self.answer_content[q3_id]["5207342292269466"] || [])[0]) && [9062626154289426, 6143316956767755].include?((self.answer_content[q3_id]["11393842755561684"] || [])[0])
          return self.review(false, auditor, "问题与其他广告相比，我更喜欢网络电影插播的广告您选择了比较赞同/非常赞同，后面问题：我非常讨厌网络电影中插播广告您选择了比较赞同/非常赞同，前后矛盾。")
        end
      end
      # 2. 与其他广告相比，我更喜欢网络电影插播的广告选择比较不赞同/非常不赞同、与其他广告相比，我更喜欢网络电影插播的广告选择比较不赞同/非常不赞同拒绝
      if self.answer_content[q3_id].present?
        if [8997379521661354, 27089357110848824].include?((self.answer_content[q3_id]["5207342292269466"] || [])[0]) && [8997379521661354, 27089357110848824].include?((self.answer_content[q3_id]["11393842755561684"] || [])[0])
          return self.review(false, auditor, "问题与其他广告相比，我更喜欢网络电影插播的广告您选择了比较不赞同/非常不赞同，后面问题：与其他广告相比，我更喜欢网络电影插播的广告您选择了比较不赞同/非常不赞同，前后矛盾。")
        end
      end
      # 3. 矩阵题全部选择一般的也拒绝
      normal = true
      self.answer_content[q3_id].each do |k, v|
        normal = normal && (v[0] == 3335537826239578)
      end
      if self.answer_content[q3_id].present? && normal
        return self.review(false, auditor, "回答不认真，没有认真查看题目进行作答，系统检测到很多答案数据都是一样的，数据不真实。")
      end
      # C5.您同意以下有关网络（手机/Ipad等平板电脑）电影插播广告的说法吗？
      q4_id = "53868990eb0e5ba25700003b"
      # 1. 我比较信任手机/平板电脑电影插播的广告选择比较赞同/非常赞同、我不信任手机/平板电脑电影中插播的广告选择比较赞同/非常赞同拒绝
      if self.answer_content[q4_id].present?
        if [7978564115681052, 6154692975073981].include?((self.answer_content[q4_id]["25632313150730480"] || [])[0]) && [7978564115681052, 6154692975073981].include?((self.answer_content[q4_id]["14452145607450622"] || [])[0])
          return self.review(false, auditor, "问题我比较信任手机/平板电脑电影插播的广告您选择了比较赞同/非常赞同，后面问题：我不信任手机/平板电脑电影中插播的广告您选择了比较赞同/非常赞同，前后矛盾。")
        end
      end
      # 2. 我比较信任手机/平板电脑电影插播的广告选择比较不赞同/非常不赞同、我不信任手机/平板电脑电影中插播的广告选择比较不赞同/非常不赞同拒绝
      if self.answer_content[q4_id].present?
        if [9031516343611972, 16483986294659660].include?((self.answer_content[q4_id]["25632313150730480"] || [])[0]) && [9031516343611972, 16483986294659660].include?((self.answer_content[q4_id]["14452145607450622"] || [])[0])
          return self.review(false, auditor, "问题我比较信任手机/平板电脑电影插播的广告您选择了比较不赞同/非常不赞同，后面问题：我不信任手机/平板电脑电影中插播的广告您选择比较不赞同/非常不赞同，前后矛盾。")
        end
      end
      # 3. 矩阵题全部选择一般的也拒绝
      normal = true
      self.answer_content[q4_id].each do |k, v|
        normal = normal && (v[0] == 1815856650151224)
      end
      if self.answer_content[q4_id].present? && normal
        return self.review(false, auditor, "回答不认真，没有认真查看题目进行作答，系统检测到很多答案数据都是一样的，数据不真实。")
      end
      # D5.有关电视上看电影插播广告的说法吗？
      q5_id = "53868990eb0e5ba257000041"
      # 1. 与其他广告相比，我更喜欢电视电视频道放电影时插播的广告选择比较赞同/非常赞同、我很讨厌电视频道放电影时插播广告选择比较赞同/非常赞同拒绝
      if self.answer_content[q5_id].present?
        if [8659700404637786, 7329218050968479].include?((self.answer_content[q5_id]["2719628209763542"] || [])[0]) && [8659700404637786, 7329218050968479].include?((self.answer_content[q5_id]["22995758073203130"] || [])[0])
          return self.review(false, auditor, "问题与其他广告相比，我更喜欢电视电视频道放电影时插播的广告您选择了比较赞同/非常赞同，后面问题: 我很讨厌电视频道放电影时插播广告您选择了比较赞同/非常赞同，前后矛盾。")
        end
      end
      # 2. 与其他广告相比，我更喜欢电视电视频道放电影时插播的广告选择比较不赞同/非常不赞同、我很讨厌电视频道放电影时插播广告选择比较不赞同/非常不赞同拒绝
      if self.answer_content[q5_id].present?
        if [8762413559704065, 19016706118088084].include?((self.answer_content[q5_id]["2719628209763542"] || [])[0]) && [8762413559704065, 19016706118088084].include?((self.answer_content[q5_id]["22995758073203130"] || [])[0])
          return self.review(false, auditor, "问题与其他广告相比，我更喜欢电视电视频道放电影时插播的广告您选择了比较不赞同/非常不赞同，后面问题: 我很讨厌电视频道放电影时插播广告您选择了比较不赞同/非常不赞同，前后矛盾。")
        end
      end
      # 3. 矩阵题全部选择一般的也拒绝
      normal = true
      self.answer_content[q5_id].each do |k, v|
        normal = normal && (v[0] == 2770931201796639)
      end
      if self.answer_content[q5_id].present? && normal
        return self.review(false, auditor, "回答不认真，没有认真查看题目进行作答，系统检测到很多答案数据都是一样的，数据不真实。")
      end
    when "5388279feb0e5b9d630000e2"
      # 问卷吧嘉年华小任务（编号：MTJC-03）
      q1_id = "53882951eb0e5b2922000041"
      q2_id = "5388296feb0e5b2922000044"
      return if self.answer_content[q1_id].blank? || self.answer_content[q2_id].blank?
      # 如果11题选择了工作日“基本上全天挂着”，那么12题选择下图红框内任意一个都会被拒绝
      if self.answer_content[q1_id]["65898603455285"].include?(14858394562312644) && (self.answer_content[q2_id]["2978021165598964"] & [6608992363315114, 8467625290988152, 2460868964029945, 2057838799813489, 17464662733559188, 21491070367932970, 19804991962459590]).present?
        return self.review(false, auditor, "您在回答工作日通常在什么时间通过手机/平板电脑上网的问题时，选择了基本上全天都挂着；在回答工作日每次通过手机/平板电脑上网的时间有多长的问题时，选择的时间较短，前后矛盾，没有认真答题。")
      end
      # 如果11题选择了周六周日“基本上全天挂着”，那么12题选择下图红框内任意一个都会被拒绝
      if self.answer_content[q1_id]["726508114874852"].include?(14858394562312644) && (self.answer_content[q2_id]["456915970214569"] & [6608992363315114, 8467625290988152, 2460868964029945, 2057838799813489, 17464662733559188, 21491070367932970, 19804991962459590]).present?
        return self.review(false, auditor, "您在回答周六、周日通常在什么时间通过手机/平板电脑上网的问题时，选择了基本上全天都挂着；在回答周六、周日每次通过手机/平板电脑上网的时间有多长的问题时，选择的时间较短，前后矛盾，没有认真答题。")
      end
    when "53842c9aeb0e5bbcb90000a1"
      # 问卷吧嘉年华小任务（编号：XFXW-03）
      # 1. 买房不如租房，省下的钱可以再进行其他投资选择非常赞同/比较赞同，够交首付款了，就立即买房，哪怕要做房奴也无所谓选择非常赞同/比较赞时拒绝。
      # 拒绝理由：问题：买房不如租房，省下的钱可以再进行其他投资您选择了选择非常赞同/比较赞同，后面问题：够交首付款了，就立即买房，哪怕要做房奴也无所谓，您选择了非常赞同/比较赞同，前后矛盾。
      qid = "53842c9aeb0e5bbcb90000b9"
      if self.answer_content[qid].present?
        if [9851430721501932, 1354350224157874].include?(self.answer_content[qid]["6377448048371890"][0]) && [9851430721501932, 1354350224157874].include?(self.answer_content[qid]["8094893003381247"][0])
          return self.review(false, auditor, "问题：买房不如租房，省下的钱可以再进行其他投资您选择了选择非常赞同/比较赞同，后面问题：够交首付款了，就立即买房，哪怕要做房奴也无所谓，您选择了非常赞同/比较赞同，前后矛盾。")
        end
        # 2. 买房不如租房，省下的钱可以再进行其他投资选择比较不赞同/非常不赞成同，够交首付款了，就立即买房，哪怕要做房奴也无所谓选择比较不赞同/非常不赞成时拒绝。
        # 拒绝理由：问题：买房不如租房，省下的钱可以再进行其他投资您选择了选择了赞同/非常不赞成同，后面问题：够交首付款了，就立即买房，哪怕要做房奴也无所谓，您选择了比较不赞同/非常不赞成同，前后矛盾。
        if [9282991777352414, 17442556690362260].include?(self.answer_content[qid]["6377448048371890"][0]) && [9282991777352414, 17442556690362260].include?(self.answer_content[qid]["8094893003381247"][0])
          return self.review(false, auditor, "问题：买房不如租房，省下的钱可以再进行其他投资您选择了选择了赞同/非常不赞成同，后面问题：够交首付款了，就立即买房，哪怕要做房奴也无所谓，您选择了比较不赞同/非常不赞成同，前后矛盾。")
        end
        # 3. 现在房价太高，与其买新房不如买一个质量好的二手房选择非常赞同/比较赞同、即使房价高一些，我也觉得买新房比买二手房好选择非常赞同/比较赞时拒绝
        # 拒绝理由：问题：现在房价太高，与其买新房不如买一个质量好的二手房您选择了非常赞同/比较赞同，后面问题：即使房价高一些，我也觉得买新房比买二手房好，您选择了非常赞同/比较赞同，前后矛盾。
        if [9851430721501932, 1354350224157874].include?((self.answer_content[qid]["5790746457359993"] || [])[0]) && [9851430721501932, 1354350224157874].include?((self.answer_content[qid]["23111421468531964"] || [])[0])
          return self.review(false, auditor, "问题：现在房价太高，与其买新房不如买一个质量好的二手房您选择了非常赞同/比较赞同，后面问题：即使房价高一些，我也觉得买新房比买二手房好，您选择了非常赞同/比较赞同，前后矛盾。")
        end
        # 4. 现在房价太高，与其买新房不如买一个质量好的二手房选择比较不赞同/非常不赞成、即使房价高一些，我也觉得买新房比买二手房好选择比较不赞同/非常不赞成时拒绝
        # 拒绝理由：问题：现在房价太高，与其买新房不如买一个质量好的二手房您选择了比较不赞同/非常不赞成，后面问题：即使房价高一些，我也觉得买新房比买二手房好，您选择了比较不赞同/非常不赞成，前后矛盾。
        if [9282991777352414, 17442556690362260].include?((self.answer_content[qid]["5790746457359993"] || [])[0]) && [9282991777352414, 17442556690362260].include?((self.answer_content[qid]["23111421468531964"] || [])[0])
          return self.review(false, auditor, "问题：现在房价太高，与其买新房不如买一个质量好的二手房您选择了比较不赞同/非常不赞成，后面问题：即使房价高一些，我也觉得买新房比买二手房好，您选择了比较不赞同/非常不赞成，前后矛盾。")
        end
        # 5. 矩阵题全部选择一般的也拒绝。
        # 拒绝理由：回答不认真，没有认真查看题目进行作答，系统检测到很多答案数据都是一样的，数据不真实。
        normal = true
        self.answer_content[qid].each do |k, v|
          normal = normal && (v[0] == 7954243128112563)
        end
        if normal
          return self.review(false, auditor, "回答不认真，没有认真查看题目进行作答，系统检测到很多答案数据都是一样的，数据不真实。")
        end
      end
    end
  end

  def self.check_contradiction
    # 53842c9aeb0e5bbcb90000a1: XFXW-03
    # 5388279feb0e5b9d630000e2: MTJC-03
    # 53868990eb0e5ba257000025: GGJC
    # 53842d30eb0e5bb228000008: XFXW-04
    # 5385982aeb0e5b7282000022: XFXW-05
    # 53843187eb0e5b2ac8000037: XFXW-06
    # 5384282deb0e5bbcb900002b: XFXW-02
    ["5385982aeb0e5b7282000022", "53843187eb0e5b2ac8000037", "5384282deb0e5bbcb900002b"].each do |sid|
      Survey.find(sid).answers.where(status: Answer::UNDER_REVIEW).each do |a|
        a.check_contradiction
      end
    end
  end
end
