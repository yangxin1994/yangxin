# encoding: utf-8
class AnswerTask < Answer

  include Mongoid::Document

  field :identifier, :type => String
  # field :origin_url, :type => String
  # field :origin_route, :type => String

  def self.status_sync(options)
    survey = SurveyTask.where("identifier" => options[:survey_id]).first
    return false unless options[:survey_id] && survey
    answer = AnswerTask.where(:survey_id => survey.id, :identifier => options[:identifier]).first
    if answer
      answer.update_attributes(options[:answer])
    else
      user = User.where(:id => options[:user_id]).first
      answer = AnswerTask.new(options[:answer])
      survey.answers << answer
      user.answers << answer if user
      answer.save
    end
  end
  
end