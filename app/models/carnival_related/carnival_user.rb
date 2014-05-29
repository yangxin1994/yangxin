require 'error_enum'
require 'securerandom'
class CarnivalUser

  include Mongoid::Document
  include Mongoid::Timestamps
  include FindTool

  NOT_EXIST = 0
  EDIT = 1
  REJECT = 2
  UNDER_REVIEW = 4
  FINISH = 32

  field :email, type: String, default: ""
  field :introducer_id, type: String

  # 0 for not exist, 1 for edit, 2 for reject, 32 for finish
  field :pre_survey_status, type: Integer, default: 0
  field :background_survey_status, type: Integer, default: 0
  field :survey_order, type: Array
  field :survey_status, type: Array, default: Array.new(14) { 0 }
  field :reward_status, type: Array, default: Array.new(3) { 0 }

  has_many :answers
  has_many :carnival_orders

  def self.create_new(introducer_id)
    u = CarnivalUser.create(introducer_id: introducer_id)
    u.survey_order = Carnival::SURVEY.shuffle
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
  end

  def survey_reviewed(answer_id, answer_status)
    answer = Answer.find(answer_id)
    index = self.survey_order.index(answer.survey_id.to_s)
    self.survey_status[index] = answer_status == Answer::FINISH ? FINISH : REJECT
    self.save

    # update quota if the answer passed review
    if answer_status == Answer::FINISH
      pre_survey_answer = self.answers.find(Carnival::PRE_SURVEY)
      Carnival.update_survey_quota(pre_survey_answer, answer.survey_id.to_s)
    end

    # handle order

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
      end
      # 3. 预调研里过去一年在“笔记本电脑/台式机”看过电影的用户才回答B1-B6。
      if !pre_survey_answer.answer_content[qid]["selection"].include?(9419552569209770)
        # hide B1-B6
      end
      # 4. 预调研里过去一年在“平板”或“手机”看过电影的用户才回答C1-C6。
      if (pre_survey_answer.answer_content[qid]["selection"] & [2214434698414035, 22230203902982316]).blank?
        # hide C1-C6
      end
      # 5. 预调研里过去一年在“电视”看过电影的用户才回答D1-D6。
      if !pre_survey_answer.answer_content[qid]["selection"].include?(11346015633717332)
        # hide D1-D6
      end
    end
    
    # 538436c9eb0e5bf8cf00003d
    # 1. 所有样本都回答E1-E6题。
    # 2. 预调研里过去一年在“电视”看过电影的用户才回答D1-D16题。

    # 5384282deb0e5bbcb900002b
    # “男性”回答B1-B9，“女性”回答B10-B27

    answer.save
  end
end
