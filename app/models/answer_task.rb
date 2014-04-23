# encoding: utf-8
class AnswerTask < Answer

  include Mongoid::Document

  field :identifier, :type => String
  # field :origin_url, :type => String
  # field :origin_route, :type => String

  def self.status_sync(options)
    survey = SurveyTask.where(:identifier => options[:survey_id]).first
    return false unless options[:survey_id] && survey
    answer = AnswerTask.where(:identifier => options[:identifier]).first
    status = options[:answer].delete(:status)
    if answer
      answer.survey = survey if answer.survey.nil?
      return false if answer.survey.identifier != options[:survey_id]
      answer.update_attributes(options[:answer])
    else
      user = User.where(:id => options[:user_id]).first
      # answer = AnswerTask.new(options[:answer])
      # survey.answers << answer
      answer = AnswerTask.create_answer(survey.id, options[:reward_scheme_id], nil, nil, options[:answer])
      if user
        user.answers << answer 
        user.save
      end
    end
    answer.save
    case status
    when 32
      if !answer.reward_delivered
        answer.finish
      end
    end    
  end
  
end