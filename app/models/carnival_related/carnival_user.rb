# encoding: utf-8
require 'error_enum'
require 'securerandom'
class CarnivalUser

  include Mongoid::Document
  include Mongoid::Timestamps
  include FindTool

  # survey status
  NOT_EXIST = 0
  REJECT = 2
  UNDER_REVIEW = 4
  FINISH = 32
  HIDE = 64

  # reward_status
  REWARD_NOT_EXIST = 0
  REWARD_EXIST = 1

  # return value for drawing lottery
  USER_NOT_EXIST = -1
  BACKGROUND_SURVEY_NOT_FINISHED = -2
  SURVEY_NOT_FINISHED = -3
  REWARD_ASSIGNED = -4
  UNLUCKY = -5
  MOBILE_EXIST = -6
  ALREADY_HIT = -7
  MOBILE_NOT_PRESENT = -8


  field :mobile, type: String, default: ""
  field :introducer_id, type: String
  field :source, type: String
  field :introducer_reward_assigned, type: Boolean, default: false

  # 0 for not exist, 2 for reject, 32 for finish
  field :pre_survey_status, type: Integer, default: 0
  field :background_survey_status, type: Integer, default: 32
  field :survey_order, type: Array
  field :reward_scheme_order, type: Array
  field :survey_status, type: Array, default: Array.new(14) { 0 }
  field :lottery_status, type: Array, default: Array.new(2) { 0 }

  field :share_num, type: Integer, default: 0
  field :share_lottery_num, type: Integer, default: 0

  field :no_reward, type: Boolean, default: false

  has_many :answers
  has_many :carnival_orders
  has_many :carnival_logs

  def self.create_new(introducer_id, source, no_reward = false)
    u = CarnivalUser.create(introducer_id: introducer_id, source: source, no_reward: no_reward)
    u.survey_order = Carnival::SURVEY.shuffle
    u.reward_scheme_order = u.survey_order.map do |e|
      s = Survey.find(e)
      s.reward_schemes.where(need_review: true).first.id.to_s
    end
    u.save
    u
  end

  def pre_survey_result(result)
    if result
      self.update_attributes(pre_survey_status: FINISH)
    else
      self.update_attributes(pre_survey_status: REJECT)
    end
  end

  def hide_survey(answer)
    # based on the user's pre survey result, some surveys are hidden
    qid = "538591d6eb0e5b7282000007"
    a = answer.answer_content[qid]["selection"]

    # 53843373eb0e5bac1d00002f: 预调研里过去一年去电影院/汽车影院看过电影的用户才回答此问卷
    s1_id = "53843373eb0e5bac1d00002f"
    input_ids_1 = [613766637056106, 8188468568300061]
    if (input_ids_1 & a).blank?
      index = self.survey_order.index(s1_id)
      self.survey_status[index] = HIDE
    end

    # 538415caeb0e5b815400000b: 预调研里过去一年在“笔记本电脑/台式机”看过电影的用户才回答此问卷
    s2_id = "538415caeb0e5b815400000b"
    input_ids_2 = [9419552569209770]
    if (input_ids_2 & a).blank?
      index = self.survey_order.index(s2_id)
      self.survey_status[index] = HIDE
    end

    # 53843581eb0e5bff58000001: 预调研里过去一年在“平板”或“手机”看过电影的用户才回答此问卷
    s3_id = "53843581eb0e5bff58000001"
    input_ids_3 = [2214434698414035, 22230203902982316]
    if (input_ids_3 & a).blank?
      index = self.survey_order.index(s3_id)
      self.survey_status[index] = HIDE
    end

    s4_id = "53859a0deb0e5b2452000021"
    qid = "5385919deb0e5b7282000004"
    if !answer.answer_content[qid]["selection"].include?(4115158460088965) && !answer.answer_content[qid]["selection"].include?(6547096649221507)
      index = self.survey_order.index(s4_id)
      self.survey_status[index] = HIDE
      self.save
    end

    s5_id = "53881af6eb0e5bb25600001d"
    qid = "5385919deb0e5b7282000004"
    if !answer.answer_content[qid]["selection"].include?(18295341391711480) && !answer.answer_content[qid]["selection"].include?(22228735216556990)
      index = self.survey_order.index(s5_id)
      self.survey_status[index] = HIDE
      self.save
    end

    s6_id = "5388279feb0e5b9d630000e2"
    qid = "5385919deb0e5b7282000004"
    if !answer.answer_content[qid]["selection"].include?(29048866216688388) && !answer.answer_content[qid]["selection"].include?(25714631368535548)
      index = self.survey_order.index(s6_id)
      self.survey_status[index] = HIDE
      self.save
    end

    self.save
  end

  def survey_finished(answer_id)
    answer = Answer.find(answer_id)
    # answer.check_matrix_answer
    index = self.survey_order.index(answer.survey_id.to_s)
    self.survey_status[index] = UNDER_REVIEW
    self.save

    return if self.no_reward == true
    # handle order
    if index <= 4
      order = self.carnival_orders.where(type: CarnivalOrder::STAGE_1).first
      if (self.survey_status[0..4] & [UNDER_REVIEW]).present?
        order.under_review if order.present?
      end
    elsif index <= 9
      order = self.carnival_orders.where(type: CarnivalOrder::STAGE_2).first
      if (self.survey_status[5..9] & [UNDER_REVIEW]).present?
        order.under_review if order.present?
      end
    else
      o1 = self.carnival_orders.where(type: CarnivalOrder::STAGE_3).first
      o2 = self.carnival_orders.where(type: CarnivalOrder::STAGE_3_LOTTERY).first
      if (self.survey_status[10..13] & [UNDER_REVIEW]).present?
        o1.under_review if o1.present?
        o2.under_review if o2.present?
      end
    end
  end

  def survey_reviewed(answer_id, answer_status)
    answer = Answer.find(answer_id)
    index = self.survey_order.index(answer.survey_id.to_s)
    old_status = self.survey_status[index]

    if answer_status == Answer::FINISH
      self.survey_status[index] = FINISH
    else
      self.survey_status[index] = REJECT
      answer.set_redo
      answer.save
      if self.mobile.present?
        # send sms to invite the sample answer again
        SmsWorker.perform_async("carnival_re_invitation", self.mobile, "", answer_id: answer_id.to_s)
      end
    end
    self.save

    # update quota if the answer passed review
    if answer_status == Answer::FINISH
      pre_survey_answer = self.answers.where(survey_id: Carnival::PRE_SURVEY).first
      Carnival.update_survey_quota(pre_survey_answer, answer.survey_id.to_s)
    elsif answer_status == Answer::REJECT && old_status == FINISH
      pre_survey_answer = self.answers.where(survey_id: Carnival::PRE_SURVEY).first
      Carnival.update_survey_quota(pre_survey_answer, answer.survey_id.to_s, false)
    end

    return if self.no_reward == true
    # handle order
    if index <= 4
      order = self.carnival_orders.where(type: CarnivalOrder::STAGE_1).first
      if (self.survey_status[0..4] & [REJECT]).present?
        order.reject if order.present?
      elsif (self.survey_status[0..4] & [REJECT, NOT_EXIST, UNDER_REVIEW]).blank?
        order.pass if order.present?
      end
    elsif index <= 9
      order = self.carnival_orders.where(type: CarnivalOrder::STAGE_2).first
      if (self.survey_status[5..9] & [REJECT]).present?
        order.reject if order.present?
      elsif (self.survey_status[5..9] & [REJECT, NOT_EXIST, UNDER_REVIEW]).blank?
        order.pass if order.present?
      end
    else
      o1 = self.carnival_orders.where(type: CarnivalOrder::STAGE_3).first
      o2 = self.carnival_orders.where(type: CarnivalOrder::STAGE_3_LOTTERY).first
      if (self.survey_status[10..13] & [REJECT]).present?
        o1.reject if o1.present?
        o2.reject if o2.present?
      elsif (self.survey_status[10..13] & [REJECT, NOT_EXIST, UNDER_REVIEW]).blank?
        o1.pass if o1.present?
        o2.pass if o2.present?
      end
    end
  end

  def fill_answer(answer)
    # based on the user's pre survey answer, some questions are hidden
    pre_survey_answer = self.answers.where(survey_id: Carnival::PRE_SURVEY).first

    s1_id = "53868990eb0e5ba257000025"
    if answer.survey_id.to_s == s1_id
      # 1. 所有样本都回答S3题。
      # 2. 预调研里过去一年在“影院”和“汽车影院”看过电影的用户才回答A1-A7题。
      qid = "538591d6eb0e5b7282000007"
      if (pre_survey_answer.answer_content[qid]["selection"] & [8188468568300061, 613766637056106]).blank?
        # hide A1-A7
        ["53868990eb0e5ba25700002a", "53868990eb0e5ba25700002b", "53868990eb0e5ba25700002c", "53868990eb0e5ba25700002d", "53868990eb0e5ba25700002e", "53868990eb0e5ba25700002f", "53868990eb0e5ba257000030"].each do |qid|
          answer.answer_content[qid] = {}
        end
      end
      # 3. 预调研里过去一年在“笔记本电脑/台式机”看过电影的用户才回答B1-B6。
      if !pre_survey_answer.answer_content[qid]["selection"].include?(9419552569209770)
        # hide B1-B6
        ["53868990eb0e5ba257000031", "53868990eb0e5ba257000032", "53868990eb0e5ba257000033", "53868990eb0e5ba257000034", "53868990eb0e5ba257000035", "53868990eb0e5ba257000036"].each do |qid|
          answer.answer_content[qid] = {}
        end
      end
      # 4. 预调研里过去一年在“平板”或“手机”看过电影的用户才回答C1-C6。
      if (pre_survey_answer.answer_content[qid]["selection"] & [2214434698414035, 22230203902982316]).blank?
        # hide C1-C6
        ["53868990eb0e5ba257000037", "53868990eb0e5ba257000038", "53868990eb0e5ba257000039", "53868990eb0e5ba25700003a", "53868990eb0e5ba25700003b", "53868990eb0e5ba25700003c"].each do |qid|
          answer.answer_content[qid] = {}
        end
      end
      # 5. 预调研里过去一年在“电视”看过电影的用户才回答D1-D6。
      if !pre_survey_answer.answer_content[qid]["selection"].include?(11346015633717332)
        # hide D1-D6
        ["53868990eb0e5ba25700003d", "53868990eb0e5ba25700003e", "53868990eb0e5ba25700003f", "53868990eb0e5ba257000040", "53868990eb0e5ba257000041", "53868990eb0e5ba257000042"].each do |qid|
          answer.answer_content[qid] = {}
        end
      end
    end
    
    s2_id = "538436c9eb0e5bf8cf00003d"
    if answer.survey_id.to_s == s2_id
      # 1. 所有样本都回答E1-E6题。
      # 2. 预调研里过去一年在“电视”看过电影的用户才回答D1-D16题。
      qid = "538591d6eb0e5b7282000007"
      if !pre_survey_answer.answer_content[qid]["selection"].include?(11346015633717332)
        # hide D1-D16
        ["538436c9eb0e5bf8cf000052", "538436c9eb0e5bf8cf000053", "538436c9eb0e5bf8cf000054", "538436c9eb0e5bf8cf000055", "538436c9eb0e5bf8cf000056", "538436c9eb0e5bf8cf000057", "538436c9eb0e5bf8cf000058", "538436c9eb0e5bf8cf000059", "538436c9eb0e5bf8cf00005a", "538436c9eb0e5bf8cf00005b", "538436c9eb0e5bf8cf00005c", "538436c9eb0e5bf8cf00005d", "538436c9eb0e5bf8cf00005e", "538436c9eb0e5bf8cf00005f", "538436c9eb0e5bf8cf000060", "538436c9eb0e5bf8cf000061"].each do |qid|
          answer.answer_content[qid] = {}
        end
      end
    end

    s3_id = "5384282deb0e5bbcb900002b"
    if answer.survey_id.to_s == s3_id
      # “男性”回答B1-B9，“女性”回答B10-B27
      qid = "538591f8eb0e5b7282000009"
      if pre_survey_answer.answer_content[qid]["selection"].include?(9735976263679518)
        # male, hide B10-B27
        ["5384282deb0e5bbcb9000041", "5384282deb0e5bbcb9000042", "5384282deb0e5bbcb9000043", "5384282deb0e5bbcb9000044", "5384282deb0e5bbcb9000045", "5384282deb0e5bbcb9000046", "5384282deb0e5bbcb9000047", "5384282deb0e5bbcb9000048", "5384282deb0e5bbcb9000049", "5384282deb0e5bbcb900004a", "5384282deb0e5bbcb900004b", "5384282deb0e5bbcb900004c", "5384282deb0e5bbcb900004d", "5384282deb0e5bbcb900004e", "5384282deb0e5bbcb900004f", "5384282deb0e5bbcb9000050", "5384282deb0e5bbcb9000051", "5384282deb0e5bbcb9000052", "5384282deb0e5bbcb9000053", "5384282deb0e5bbcb9000054", "5384282deb0e5bbcb9000055", "5384282deb0e5bbcb9000056", "5384282deb0e5bbcb9000057", "5384282deb0e5bbcb9000058", "5384282deb0e5bbcb9000059", "5384282deb0e5bbcb900005a", "5384282deb0e5bbcb900005b", "5384282deb0e5bbcb900005c", "5384282deb0e5bbcb900005d", "5384282deb0e5bbcb900005e", "5384282deb0e5bbcb900005f", "5384282deb0e5bbcb9000060", "5384282deb0e5bbcb9000061", "5384282deb0e5bbcb9000062", "5384282deb0e5bbcb9000063", "5384282deb0e5bbcb9000064", "5384282deb0e5bbcb9000065", "5384282deb0e5bbcb9000066", "5384282deb0e5bbcb9000067", "5384282deb0e5bbcb9000068", "5384282deb0e5bbcb9000069"].each do |qid|
          answer.answer_content[qid] = {}
        end
      else
        # femail, hide B1-B9
        ["5384282deb0e5bbcb900002e", "5384282deb0e5bbcb900002f", "5384282deb0e5bbcb9000030", "5384282deb0e5bbcb9000031", "5384282deb0e5bbcb9000032", "5384282deb0e5bbcb9000033", "5384282deb0e5bbcb9000034", "5384282deb0e5bbcb9000035", "5384282deb0e5bbcb9000036", "5384282deb0e5bbcb9000037", "5384282deb0e5bbcb9000038", "5384282deb0e5bbcb9000039", "5384282deb0e5bbcb900003a", "5384282deb0e5bbcb900003b", "5384282deb0e5bbcb900003c", "5384282deb0e5bbcb900003d", "5384282deb0e5bbcb900003e", "5384282deb0e5bbcb900003f", "5384282deb0e5bbcb9000040"].each do |qid|
          answer.answer_content[qid] = {}
        end
      end
    end

    s4_id = "53859a0deb0e5b2452000021"
    if answer.survey_id.to_s == s4_id
      # 1. 预调研过去一年看过电视的回答A系列问题；
      qid = "5385919deb0e5b7282000004"
      if !pre_survey_answer.answer_content[qid]["selection"].include?(4115158460088965)
        # do not watch tv, hide the A series questions
        ["538808cceb0e5b27df000081", "5388091feb0e5b27df000084", "53880938eb0e5bb7d900003b", "5388098aeb0e5b27df000088", "53880a21eb0e5b27df000096", "53880a72eb0e5b67c4000001", "53880ab5eb0e5bb7d900004e", "53880acbeb0e5bb7d9000050", "53880ae2eb0e5b67c4000007"].each do |qid|
          answer.answer_content[qid] = {}
        end
      end
      # 2. 预调研过去一年读过报纸的回答B系列问题；
      if !pre_survey_answer.answer_content[qid]["selection"].include?(6547096649221507)
        # do not read newspaper, hide the B series questions
        ["53880b18eb0e5b27df0000a1", "53880b2feb0e5b67c400000c", "53880b59eb0e5b67c4000013", "53880bb1eb0e5b27df0000ab", "53880c8ceb0e5b67c4000019", "53880be0eb0e5bce4f000006", "53880cd4eb0e5b6876000014", "53880cebeb0e5bce4f000010", "53880d05eb0e5bce4f000015"].each do |qid|
          answer.answer_content[qid] = {}
        end
      end
    end

    s5_id = "53881af6eb0e5bb25600001d"
    if answer.survey_id.to_s == s5_id
      # 1. 预调研过去一年听过广播的回答C系列问题；
      qid = "5385919deb0e5b7282000004"
      if !pre_survey_answer.answer_content[qid]["selection"].include?(18295341391711480)
        # do not listen radio, hide the C series questions
        ["53881b24eb0e5bb7d90000f5", "53881b36eb0e5b9d63000048", "53881b9aeb0e5b9d6300004e", "53881bfaeb0e5bd9a7000009", "53881c33eb0e5bd9a700000f", "53881c5deb0e5b9d6300005b", "53881cffeb0e5bb25600003d", "53881d1beb0e5bd9a7000020", "53881d31eb0e5bb25600003f"].each do |qid|
          answer.answer_content[qid] = {}
        end
      end
      # 2. 预调研过去一年读过杂志的回答D系列问题；
      if !pre_survey_answer.answer_content[qid]["selection"].include?(22228735216556990)
        # do not read magzine, hide the D series questions
        ["53881d58eb0e5bb256000042", "53881d6aeb0e5bb256000043", "53881da3eb0e5b9d63000061", "53881dc9eb0e5bb256000050", "53881defeb0e5bb7d9000102", "53881e32eb0e5b9d6300006c", "53881e44eb0e5b50a2000008", "53881e5beb0e5b9d6300006d", "53881e70eb0e5b50a200000b"].each do |qid|
          answer.answer_content[qid] = {}
        end
      end
    end

    s6_id = "5388279feb0e5b9d630000e2"
    if answer.survey_id.to_s == s6_id
      # 1. 预调研过去一年用过笔记本/台式机上网的回答E系列问题；
      qid = "5385919deb0e5b7282000004"
      if !pre_survey_answer.answer_content[qid]["selection"].include?(29048866216688388)
        # do not use notepad/PC, hide the E series questions
        ["538827bfeb0e5b2922000023", "538827d6eb0e5b912d00000a", "53882811eb0e5b2922000029", "5388282deb0e5b292200002c", "53882848eb0e5b9d630000ea", "53882894eb0e5b292200002f", "538828b8eb0e5b2922000038", "538828e6eb0e5b2337000001"].each do |qid|
          answer.answer_content[qid] = {}
        end
      end
      # 2. 预调研过去一年用过手机/平板上网的回答F系列问题；
      if !pre_survey_answer.answer_content[qid]["selection"].include?(25714631368535548)
        # do not use mobile/pad, hide the F series questions
        ["5388291aeb0e5b912d000010", "53882934eb0e5b912d000015", "53882951eb0e5b2922000041", "5388296feb0e5b2922000044", "53882988eb0e5b1d89000003", "538829bbeb0e5b292200004b", "538829e0eb0e5b2922000050", "53882a04eb0e5b2922000052"].each do |qid|
          answer.answer_content[qid] = {}
        end
      end
    end

    s7_id = "5385982aeb0e5b7282000022"
    if answer.survey_id.to_s == s7_id
      # 1. B5-B7只针对女性
      qid = "538591f8eb0e5b7282000009"
      if pre_survey_answer.answer_content[qid]["selection"].include?(9735976263679518)
        # male, hide B5-B7
        ["5385982beb0e5b7282000043", "5385982beb0e5b7282000044", "5385982beb0e5b7282000045"].each do |qid|
          answer.answer_content[qid] = {}
        end
      end
    end

    answer.save
  end

  def draw_second_stage_lottery(amount)
    return "" if self.no_reward == true
    if (self.survey_status[5..9] & [NOT_EXIST, REJECT]).present?
      return SURVEY_NOT_FINISHED
    end
    if self.lottery_status[0] == REWARD_EXIST
      return REWARD_ASSIGNED
    end
    if amount == 10
      p = 1.1
    elsif amount == 50
      p = 0.18
    else
      p = 0.09
    end
    self.lottery_status[0] = REWARD_EXIST
    self.save
    return UNLUCKY if rand > p
    # create order
    order = CarnivalOrder.create(type: CarnivalOrder::STAGE_2, mobile: self.mobile, amount: amount)
    order.carnival_user = self
    if self.survey_status[5..9].include?(UNDER_REVIEW)
      order.status = CarnivalOrder::UNDER_REVIEW
    else
      order.status = CarnivalOrder::WAIT
    end
    order.save
    order.handle
    # create log
    carnival_log = CarnivalLog.create(type: CarnivalLog::STAGE_2, prize_name: "#{amount}元充值卡")
    self.carnival_logs << carnival_log
    return "#{amount}元充值卡"
  end

  def create_first_stage_order(mobile)
    u = CarnivalUser.where(mobile: mobile).first
    return "" if self.no_reward == true
    if u.present? && u.id.to_s != self.id.to_s
      return MOBILE_EXIST
    else
      self.update_attributes(mobile: mobile)
    end
    if (self.survey_status[0..4] & [NOT_EXIST, REJECT]).present?
      return SURVEY_NOT_FINISHED
    end
    #if self.carnival_orders.where(type: CarnivalOrder::STAGE_1).present?
    if self.carnival_orders.where(type: CarnivalOrder::STAGE_1).present?
      return REWARD_ASSIGNED
    end
    # create order
    order = CarnivalOrder.create(type: CarnivalOrder::STAGE_1, mobile: self.mobile, amount: 10)
    order.carnival_user = self
    if self.survey_status[0..4].include?(UNDER_REVIEW)
      order.status = CarnivalOrder::UNDER_REVIEW
    else
      order.status = CarnivalOrder::WAIT
    end
    order.save
    order.handle
    # create log
    carnival_log = CarnivalLog.create(type: CarnivalLog::STAGE_1, prize_name: "10元充值卡")
    self.carnival_logs << carnival_log

    # give introducer lottery chance
    if self.introducer_id.to_s.utf8!.present? && !self.introducer_reward_assigned
      introducer = CarnivalUser.where(id: self.introducer_id.to_s.utf8!).first
      if introducer.present?
        introducer.share_num += 1
        introducer.save
      end
      self.introducer_reward_assigned = true
      self.save
      # create log
      if introducer.present?
        carnival_log = CarnivalLog.create(type: CarnivalLog::SHARE, prize_name: "一次抽大奖机会")
        introducer.carnival_logs << carnival_log
      end
    end

    return "10元充值卡"
  end

  def self.assign_share_lottery
    CarnivalUser.all.each do |c|
      puts c.id.to_s
      if c.introducer_id.to_s.utf8!.present? && !c.introducer_reward_assigned && c.mobile.present?
        introducer = CarnivalUser.where(id: c.introducer_id.to_s.utf8!).first
        if introducer.present?
          introducer.share_num += 1
          introducer.save
        end
        c.introducer_reward_assigned = true
        c.save
        # create log
        carnival_log = CarnivalLog.create(type: CarnivalLog::SHARE, prize_name: "一次抽大奖机会")
        introducer.carnival_logs << carnival_log if introducer.present?
      end
    end
  end

  def create_third_stage_mobile_order
    return "" if self.no_reward == true
    if (self.survey_status[10..13] & [NOT_EXIST, REJECT]).present?
      return SURVEY_NOT_FINISHED
    end
    #if self.carnival_orders.where(type: CarnivalOrder::STAGE_3).present?
    if self.carnival_orders.where(type: CarnivalOrder::STAGE_3).present?
      return REWARD_ASSIGNED
    end
    # create order
    order = CarnivalOrder.create(type: CarnivalOrder::STAGE_3, mobile: self.mobile, amount: 10)
    order.carnival_user = self
    if self.survey_status[10..13].include?(UNDER_REVIEW)
      order.status = CarnivalOrder::UNDER_REVIEW
    else
      order.status = CarnivalOrder::WAIT
    end
    order.save
    order.handle
    # create log
    carnival_log = CarnivalLog.create(type: CarnivalLog::STAGE_3, prize_name: "10元充值卡")
    self.carnival_logs << carnival_log
    return "10元充值卡"
  end

  def draw_third_stage_lottery
    return "" if self.no_reward == true
    if (self.survey_status[10..13] & [NOT_EXIST, REJECT]).present?
      return SURVEY_NOT_FINISHED
    end
    if self.lottery_status[1] == REWARD_EXIST
      return REWARD_ASSIGNED
    end
    if self.carnival_orders.where(:type.in => [CarnivalOrder::STAGE_3_LOTTERY, CarnivalOrder::SHARE]).first.present?
      return ALREADY_HIT
    end
    self.lottery_status[1] = REWARD_EXIST
    self.save

    ### draw
    prize = CarnivalPrize.draw
    return UNLUCKY if prize.blank?
    order = CarnivalOrder.create(type: CarnivalOrder::STAGE_3_LOTTERY, mobile: self.mobile)
    order.carnival_prize = prize
    order.carnival_user = self
    if self.survey_status[10..13].include?(UNDER_REVIEW)
      order.status = CarnivalOrder::UNDER_REVIEW
    else
      order.status = CarnivalOrder::WAIT
    end
    order.save
    # create log
    carnival_log = CarnivalLog.create(type: CarnivalLog::STAGE_3_LOTTERY, prize_name: order.carnival_prize.name)
    self.carnival_logs << carnival_log
    return order.carnival_prize.name
  end

  def draw_share_lottery
    if (self.survey_status & [NOT_EXIST, REJECT]).present?
      return SURVEY_NOT_FINISHED
    end
    if self.share_num <= self.share_lottery_num
      return REWARD_ASSIGNED
    end
    if self.carnival_orders.where(:type.in => [CarnivalOrder::STAGE_3_LOTTERY, CarnivalOrder::SHARE]).first.present?
      return ALREADY_HIT
    end
    self.share_lottery_num += 1
    self.save

    ### draw
    prize = CarnivalPrize.draw

    return UNLUCKY if prize.blank?
    order = CarnivalOrder.create(type: CarnivalOrder::SHARE, mobile: self.mobile)
    order.carnival_prize = prize
    order.carnival_user = self
    order.status = CarnivalOrder::WAIT
    order.save
    # create log
    carnival_log = CarnivalLog.create(type: CarnivalLog::SHARE_LOTTERY, prize_name: order.carnival_prize.name)
    self.carnival_logs << carnival_log
    return order.carnival_prize.name
  end
end
