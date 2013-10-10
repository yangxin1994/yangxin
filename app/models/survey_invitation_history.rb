class SurveyInvitationHistory
  
  include Mongoid::Document
  include Mongoid::Timestamps
  field :type, :type => String
  # 0 for ongoing, 1 for finished
  belongs_to :user
  belongs_to :survey, index: true
  
  index({ survey_id: 1 }, { background: true } )

  def self.get_user_ids_sent(survey_id)
    survey = Survey.find_by_id(survey_id)
    user_ids_sent = []
    selected_user_ids = survey.survey_invitation_histories.map { |e| e.user_id.to_s }
    return selected_user_ids
  end
end
