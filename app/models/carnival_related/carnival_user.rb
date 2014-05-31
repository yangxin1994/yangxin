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


  field :mobile, type: String, default: ""
  field :introducer_id, type: String
  field :source, type: String
  field :introducer_reward_assigned, type: Boolean, default: false

  # 0 for not exist, 2 for reject, 32 for finish
  field :pre_survey_status, type: Integer, default: 0
  field :background_survey_status, type: Integer, default: 0
  field :survey_order, type: Array
  field :reward_scheme_order, type: Array
  field :survey_status, type: Array, default: Array.new(14) { 0 }
  field :lottery_status, type: Array, default: Array.new(2) { 0 }

  field :share_num, type: Integer, default: 0
  field :share_lottery_num, type: Integer, default: 0

  has_many :answers
  has_many :carnival_orders
  has_many :carnival_logs

  def self.create_new(introducer_id, source)
    u = CarnivalUser.create(introducer_id: introducer_id, source: source)
    u.survey_order = Carnival::SURVEY.shuffle
    u.reward_scheme_order = u.survey_order.map do |e|
      s = Survey.find(e)
      s.reward_schemes.where(default: true).first.id.to_s
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
      self.survey_status[index] = FINISH
    end

    # 538415caeb0e5b815400000b: 预调研里过去一年在“笔记本电脑/台式机”看过电影的用户才回答此问卷
    s2_id = "538415caeb0e5b815400000b"
    input_ids_2 = [9419552569209770]
    if (input_ids_2 & a).blank?
      index = self.survey_order.index(s2_id)
      self.survey_status[index] = FINISH
    end

    # 53843581eb0e5bff58000001: 预调研里过去一年在“平板”或“手机”看过电影的用户才回答此问卷
    s3_id = "53843581eb0e5bff58000001"
    input_ids_3 = [2214434698414035, 22230203902982316]
    if (input_ids_3 & a).blank?
      index = self.survey_order.index(s3_id)
      self.survey_status[index] = FINISH
    end

    self.save
  end

  def survey_finished(answer_id)
    answer = Answer.find(answer_id)
    index = self.survey_order.index(answer.survey_id.to_s)
    self.survey_status[index] = UNDER_REVIEW
    self.save

    # handle order
    if index <= 4
      order = self.orders.where(type: CarnivalOrder::STAGE_1).first
      if !(self.survey_status[0..4] & [REJECT, NOT_EXIST, FINISH]).present?
        order.under_review if order.present?
      end
    elsif index <= 9
      order = self.orders.where(type: CarnivalOrder::STAGE_2).first
      if !(self.survey_status[5..9] & [REJECT, NOT_EXIST, FINISH]).present?
        order.under_review if order.present?
      end
    else
      o1 = self.orders.where(type: CarnivalOrder::STAGE_3).first
      o2 = self.orders.where(type: CarnivalOrder::STAGE_3_LOTTERY).first
      if (self.survey_status[10..13] & [REJECT, NOT_EXIST, FINISH]).present?
        o1.under_review if o1.present?
        o2.under_review if o2.present?
      end
    end
  end

  def survey_reviewed(answer_id, answer_status)
    answer = Answer.find(answer_id)
    index = self.survey_order.index(answer.survey_id.to_s)
    self.survey_status[index] = answer_status == Answer::FINISH ? FINISH : REJECT

    if answer_status == Answer::FINISH
      self.survey_status[index] = FINISH
    else
      self.survey_status[index] = REJECT
      answer.set_redo
      answer.save
      if self.mobile.present?
        # send sms to invite the sample answer again
        SmsWorker.perform_async("carnival_re_invitation", self.mobile, "")
      end
    end
    self.save

    # update quota if the answer passed review
    if answer_status == Answer::FINISH
      pre_survey_answer = self.answers.find(Carnival::PRE_SURVEY)
      Carnival.update_survey_quota(pre_survey_answer, answer.survey_id.to_s)
    end

    # handle order
    if index <= 4
      order = self.orders.where(type: CarnivalOrder::STAGE_1).first
      if (self.survey_status[0..4] & [REJECT]).present?
        order.reject if order.present?
      elsif (self.survey_status[0..4] & [REJECT, NOT_EXIST, UNDER_REVIEW]).present?
        order.pass if order.present?
      end
    elsif index <= 9
      order = self.orders.where(type: CarnivalOrder::STAGE_2).first
      if (self.survey_status[5..9] & [REJECT]).present?
        order.reject if order.present?
      elsif (self.survey_status[5..9] & [REJECT, NOT_EXIST, UNDER_REVIEW]).present?
        order.pass if order.present?
      end
    else
      o1 = self.orders.where(type: CarnivalOrder::STAGE_3).first
      o2 = self.orders.where(type: CarnivalOrder::STAGE_3_LOTTERY).first
      if (self.survey_status[10..13] & [REJECT]).present?
        o1.reject if o1.present?
        o2.reject if o2.present?
      elsif (self.survey_status[10..13] & [REJECT, NOT_EXIST, UNDER_REVIEW]).present?
        o1.pass if o1.present?
        o2.pass if o2.present?
      end
    end

    # give introducer lottery chance
    if (self.survey_status & [NOT_EXIST, REJECT, UNDER_REVIEW]).blank? && self.introducer_id.present? && !self.introducer_reward_assigned
      introducer = CarnivalUser.find(self.introducer_id)
      introducer.share_num += 1
      introducer.save
      self.introducer_reward_assigned = true
      self.save
      # create log
      carnival_log = CarnivalLog.create(type: CarnivalLog::SHARE, prize_name: "一次抽大奖机会")
      self.carnival_logs << carnival_log
    end
  end

  def fill_answer(answer)
    # based on the user's pre survey answer, some questions are hidden
    pre_survey_answer = self.answers.find(Carnival::PRE_SURVEY)

    s1_id = "53868990eb0e5ba257000025"
    if answer.survey_id.to_s == s1_id
      # 1. 所有样本都回答S3题。
      # 2. 预调研里过去一年在“电视”看过电影的用户才回答A1-A7题。
      qid = "538591d6eb0e5b7282000007"
      if !pre_survey_answer.answer_content[qid]["selection"].include?(613766637056106)
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

    answer.save
  end

  def draw_second_stage_lottery(amount)
    if (self.survey_status[5..9] & [NOT_EXIST, REJECT]).present?
      return SURVEY_NOT_FINISHED
    end
    if self.lottery_status[0] == REWARD_EXIST
      return REWARD_ASSIGNED
    end
    if amount == 10
      p = 0.99
    elsif amount == 50
      p = 0.2
    else
      p = 0.1
    end
    return UNLUCKY if rand < p
    self.lottery_status[0] = REWARD_EXIST
    self.save
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
    if CarnivalUser.where(mobile: mobile).present?
      return MOBILE_EXIST
    else
      self.update_attributes(mobile: mobile)
    end
    if (self.survey_status[0..4] & [NOT_EXIST, REJECT]).present?
      return SURVEY_NOT_FINISHED
    end
    #if self.orders.where(type: CarnivalOrder::STAGE_1).present?
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
    return "10元充值卡"
  end

  def create_third_stage_mobile_order
    if (self.survey_status[10..13] & [NOT_EXIST, REJECT]).present?
      return SURVEY_NOT_FINISHED
    end
    #if self.orders.where(type: CarnivalOrder::STAGE_3).present?
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
    if (self.survey_status[10..13] & [NOT_EXIST, REJECT]).present?
      return SURVEY_NOT_FINISHED
    end
    if self.lottery_status[1] == REWARD_EXIST
      return REWARD_ASSIGNED
    end
    self.lottery_status[1] == REWARD_EXIST
    self.save

    ### draw
    prize = CarnivalPrize.draw

    return UNLUCKY if prize.blank?
    order = CarnivalOrder.create(type: CarnivalOrder::STAGE_3_LOTTERY, mobile: self.mobile)
    order.prize = prize
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
    if self.share_num <= self.share_lottery_num
      return REWARD_ASSIGNED
    end
    self.share_lottery_num += 1
    self.save

    ### draw
    prize = CarnivalPrize.draw

    return UNLUCKY if prize.blank?
    order = CarnivalOrder.create(type: CarnivalOrder::SHARE, mobile: self.mobile)
    order.prize = prize
    order.carnival_user = self
    order.status = CarnivalOrder::WAIT
    order.save
    # create log
    carnival_log = CarnivalLog.create(type: CarnivalLog::SHARE_LOTTERY, prize_name: order.carnival_prize.name)
    self.carnival_logs << carnival_log
    return order.carnival_prize.name
  end
end
