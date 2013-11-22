class PreSurveyWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false, :queue => "oopsdata_#{Rails.env}".to_sym
  def perform
    target_surveys = Survey.where(:pre_survey_promotable => true, :status => Survey::PUBLISHED)

    target_surveys.each do |survey|
      sample_id_ary = []
      sample_email_history_batch = []
      sample_ids_sent = SurveyInvitationHistory.get_user_ids_sent(survey.id.to_s)
      emails_sent = sample_ids_sent.map { |e| User.find(e).email }
      survey.pre_survey_promote_info.each do |pre_survey_setting|
        next if pre_survey_setting["published"] != true
        pre_survey = Survey.find(pre_survey_setting["survey_id"])
        answers = pre_survey.answers.not_preview.finished.where(:finished_at.gt => pre_survey_setting["last_scan_time"])
        selected_answers = answers.select do |answer|
          email = answer.answer_content[pre_survey_setting["email_question_id"]]
          satisfy = email.present? && !emails_sent.include?(email)
          pre_survey_setting["conditions"].each do |c|
            question = Question.find(c["question_id"])
            case question.type
            when QuestionTypeEnum::CHOICE_QUESTION
              satisfy &&= Tool.check_choice_question_answer(c["question_id"],
                              answer.answer_content[c["question_id"]]["selection"],
                              c["value"],
                              c["fuzzy"])
            when QuestionTypeEnum::ADDRESS_BLANK_QUESTION
              satisfy &&= Tool.check_address_blank_question_answer(c["question_id"],
                              answer.answer_content[c["question_id"]["selection"],
                              c["value"])
            end
          end
          satisfy
        end
        email_number = 0
        selected_answers.each do |answer|
          email = answer.answer_content[pre_survey_setting["email_question_id"]]
          sample = User.find_by_email(email)
          sample = User.create(email: email, status: User::VISITOR, registered_at: Time.now.to_i) if sample.blank?
          if !sample_id_ary.include?(sample.id.to_s)
            sample_id_ary << sample.id.to_s
            sample_email_history_batch << { :user_id => sample.id, :survey_id => survey._id, :type => "email" }
          end
          email_number += 1
        end
        pre_survey_setting[promote_number] += email_number
      end
      survey.save
      SurveyInvitationHistory.collection.insert(sample_email_history_batch)
      MailgunApi.batch_send_survey_email(survey.id.to_s, sample_id_ary)
    end
  end
end
