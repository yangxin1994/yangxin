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
  field :survey_status, type: Array, default: Array.new(15) { 0 }
  field :reward_status, type: Array, default: Array.new(3) { 0 }

  has_many :answers

  def self.create_new(introducer_id)
    u = CarnivalUser.create(introducer_id: introducer_id)
    u.survey_order = Carnival::SURVEY.shuffle
  end

  def pre_survey_result(result)
    if result
      self.update_attributes(pre_survey_status: FINISH)
    else
      self.update_attributes(pre_survey_status: REJECT)
    end
  end

  def survey_finished(answer_id)
    answer = Answer.find(answer_id)
    index = self.survey_order.index(answer.survey_id.to_s)
    self.survey_status[index] = UNDER_REVIEW
    self.save

    # update quota
  end

  def survey_reviewed(answer_id, answer_status)
    answer = Answer.find(answer_id)
    index = self.survey_order.index(answer.survey_id.to_s)
    self.survey_status[index] = answer_status == Answer::FINISH ? FINISH : REJECT
    self.save

    # handle order

    # update quota
  end
end
