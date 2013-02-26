class EmailHistory
	include Mongoid::Document
	include Mongoid::Timestamps
	field :success, :type => Boolean
	field :email, :type => String
	belongs_to :user
	belongs_to :survey, index: true
	index({ survey_id: 1 }, { background: true } )

	def self.get_user_ids_sent(survey_id)
		survey = Survey.find_by_id(survey_id)
		user_ids_sent = []
		selected_user_ids = survey.email_histories.map { |e| e.user_id.to_s }
		return selected_user_ids
	end

	def self.get_emails_sent(survey_id)
		survey = Survey.find_by_id(survey_id)
		emails_sent = []
		selected_emails = survey.email_histories.map { |e| e.email }
		return selected_emails.uniq
	end
end
