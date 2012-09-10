class EmailHistory
  include Mongoid::Document
  include Mongoid::Timestamps
	field :success, :type => Boolean
	belongs_to :user
	belongs_to :survey

	def self.get_user_ids_sent(survey_id)
		survey = Survey.find_by_id(survey_id)
		return survey.email_histories.map {|e| e.user_id.to_s}
	end
end
