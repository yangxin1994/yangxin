class EmailInvitationWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false, :queue => "oopsdata_#{Rails.env}".to_sym
  def perform
    # 1. get all samples, excluding those are in the blacklist
    sample_ids = User.sample.where(:email_subscribe => true, :is_block => false).map { |e| e._id.to_s }
    # 2. get the surveys that need to send emails
    published_survey = Survey.where(:email_promotable => true, :status => Survey::PUBLISHED)
    # 3. find out samples for surveys
    surveys_for_sample = {}
    published_survey.each do |survey|
      next if survey.remain_quota_number <= 0
      # find samples for each survey
      s_id = survey._id.to_s
      email_number = survey.email_promote_info["email_amount"].to_i
      next if email_number == 0
      sample_ids_answered = survey.get_user_ids_answered
      sample_ids_sent = SurveyInvitationHistory.get_user_ids_sent(s_id)
      sample_ids_available = sample_ids - sample_ids_answered - sample_ids_sent
      # check survey's quota and samples attributes
      sample_ids_selected = []
      sample_ids_unknow = []
      sample_ids_available.each do |e|
        current_sample = User.sample.find_by_id(e)
        sample_ids_selected << e if survey.sample_attributes_for_promote.blank?
        survey.sample_attributes_for_promote.each do |sample_attribute|
          v = current_sample.read_sample_attribute_by_id(sample_attribute["sample_attribute_id"])
          match = Tool.check_sample_attribute(sample_attribute["sample_attribute_id"], v, sample_attribute["value"])
          next if match == false
          if match == true
            sample_ids_selected << e
          else
            sample_ids_unknow << e
          end
          break
        end
      end
      sample_ids_not_selected = sample_ids_available - sample_ids_selected
      if sample_ids_selected.length > email_number
        sample_ids_selected = sample_ids_selected.shuffle[0..email_number - 1]
      elsif survey.email_promote_info["promote_to_undefined_sample"]
        sample_ids_selected += sample_ids_unknow.shuffle[0..email_number - 1 - sample_ids_selected.length]
      end
      sample_email_history_batch = []
      sample_ids_selected.each do |u_id|
        surveys_for_sample[u_id] ||= []
        surveys_for_sample[u_id] << survey._id.to_s
        sample = User.sample.find_by_id(u_id)
        if sample.present?
          sample_email_history_batch << { user_id: sample._id, survey_id: survey._id, type: "email", email: sample.email, mobile: sample.mobile }
        end
      end
      # update email history for samples
      SurveyInvitationHistory.collection.insert(sample_email_history_batch)
      survey.email_promote_info["promote_email_count"] += sample_email_history_batch.length
      survey.save
    end
    # 4. transform data
    samples_for_surveys = {}
    surveys_for_sample.each do |u_id, s_id_ary|
      s_id_ary.each do |s_id|
        samples_for_surveys[s_id] ||= []
        samples_for_surveys[s_id] << u_id
      end
    end
    # 5. send emails to the samples found
    samples_for_surveys.each do |s_id, sample_id_ary|
      MailgunApi.batch_send_survey_email(s_id, sample_id_ary)
    end
    return true
  end
end
