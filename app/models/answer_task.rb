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
      when "5"
        satisfy = true
      end
      return false if !satisfy
    end
    true
  end  
  
end