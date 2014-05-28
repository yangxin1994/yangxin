require 'error_enum'
require 'securerandom'
class Carnival
  include Mongoid::Document


  field :quota, type: Hash, default: {amount: 0,
    gender: [0, 0],
    age: [0, 0, 0, 0, 0, 0, 0],
    income: [0, 0, 0, 0, 0, 0],
    education: [0, 0, 0, 0, 0]}
  field :survey_id, type: String
  SETTING = 1
  STATS = 2
  field :type, type: Integer


  PRE_SURVEY = ""
  BACKGROUND_SURVEY = ""
  SURVEY = ["", ""]

  ALL_SURVEY = SURVEY + [PRE_SURVEY, BACKGROUND_SURVEY]

  def self.pre_survey_finished(answer_id)
    answer = Answer.find(answer_id)
    carnival_user = answer.carnival_user
    # check whether pass the presurvey
    result = true
    carnival_user.pre_survey_finished(result)
  end

  def self.background_survey_finished(answer_id)
    carnival_user = answer.carnival_user
    carnival_user.update(background_survey_status: CarnivalUser::FINISH)
  end

  def self.survey_finished(answer_id)
    answer = Answer.find(answer_id)
    carnival_user = answer.carnival_user
    carnival_user.survey_finished(answer.survey_id)
  end

  def self.survey_reviewed(answer_id)
    answer = Answer.find(answer_id)
    carnival_user = answer.carnival_user
    carnival_user.survey_reviewed(answer.survey_id, answer.status)
  end
end
