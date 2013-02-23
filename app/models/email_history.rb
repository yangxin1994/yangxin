class EmailHistory
	include Mongoid::Document
	include Mongoid::Timestamps
	field :success, :type => Boolean
	field :email, :type => String
	belongs_to :user
	belongs_to :survey

	def self.get_user_ids_sent(survey_id)
		survey = Survey.find_by_id(survey_id)
		user_ids_sent = []
		survey.email_histories.each do |e|
			user_ids_sent << e.user_id.to_s if !e.user.nil?
		end
		return user_ids_sent
	end

	def self.get_emails_sent(survey_id)
		survey = Survey.find_by_id(survey_id)
		emails_sent = []
		selected_email_histories = survey.email_histories.select do |e|
			!e.email.blank?
		end
		return selected_email_histories.map { |e| e.email }
	end
end
