class PreSurveyWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false, :queue => "oopsdata_#{Rails.env}".to_sym
  def perform
    PreSurvey.where(status: OPEN).each do |pre_survey|
      email_to_send = []
      mobile_to_send = []
      publish_survey = Survey.find(pre_survey.publish["survey_id"])
      publish_answers = publish_survey.answers.where(:finished_at.gt pre_survey.last_scan_time)
      selected_answers = publish_answers.select do |a|
        satisfy = false
        pre_survey.conditions.each do |condition|
          cur_satisfy = true
          condition.each do |c|
            if c["survey_id"] == pre_survey.publish["survey_id"]
              answer = a.answer_content[c["question_id"]]
            else
              if a.user.blank?
                cur_satisfy = false
                break
              else
                target_a = a.user.answers.where(survey_id: c["survey_id"]).first
                if target_a.blank?
                  cur_satisfy = false
                  break
                else
                  answer = target_a.answer_content[c["question_id"]]
                end
              end
            end
            cur_satisfy = Tool.check_choice_question_answer(c["question_id"], answer, c["answer"], c["fuzzy"])
            break if !cur_satisfy
          end
          satisfy = cur_satisfy
          break if satisfy
        end
        if satisfy
          # record the email or mobile
          email_mobile = a.answer_content[pre_survey.publish["question_id"]]
          email_to_send << email_mobile if pre_survey.publish["type"] == PreSurvey::EMAIL
          mobile_to_send << email_mobile if pre_survey.publish["type"] == PreSurvey::MOBILE
        end
      end
      # send emails and messages
      email_to_send = email_to_send - SurveyInvitationHistory.get_emails_sent(pre_survey.survey_id.to_s)
      mobile_to_send = mobile_to_send - SurveyInvitationHistory.get_mobiles_sent(pre_survey.survey_id.to_s)
      
      MailgunApi.batch_send_pre_survey_email(pre_survey.survey_id.to_s, email_to_send, pre_survey.reward_scheme_id)
      mobile_to_send.each do |mobile|
        SmsApi.pre_survey_sms(pre_survey.survey_id.to_s, mobile, pre_survey.reward_scheme_id)
      end

      email_to_send = []
      mobile_to_send = []
    end
  end
end
