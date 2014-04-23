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
      binding.pry
    if answer
      # return false if answer.survey.id != options[:survey_id]
      answer.update_attributes(options[:answer])
      case options[:answer][:status]
      when 32
        answer.finish
      end
    else
      user = User.where(:id => options[:user_id]).first
      answer = AnswerTask.new(options[:answer])
      survey.answers << answer
      if user
        user.answers << answer 
        user.save
      end
      answer.save
    end
  end
  
end