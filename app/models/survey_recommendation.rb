#encoding: utf-8
class SurveyRecommendation
	include Mongoid::Document
	# 0 for url recommendation, 1 for key words recommendation
	field :recommendation_type, :type => Integer
	# url for url recommendation, or key word for key words recommendation
	field :content, :type => String
	# 0 for normal, -1 for deleted
	field :status, :type => Integer, default: 0
	has_and_belongs_to_many :surveys, inverse_of: nil

	index({ recommendation_type: 1, status: 1 }, { background: true } )

	def self.url_recommendations(exclude_survey_ids)
		recommendations = self.where(:recommendation_type => 0, :status.gt => -1)
		url_recommendations_hash = {}
		recommendations.each do |e|
			url_recommendations_hash[e.content] = (e.survey_ids.map { |e| e.to_s }).select { |e| !exclude_survey_ids.include?(e) }
		end
		return url_recommendations_hash
	end

	def self.key_word_recommendations(exclude_survey_ids)
		recommendations = self.where(:recommendation_type => 1, :status.gt => -1)
		key_word_recommendations_hash = {}
		recommendations.each do |e|
			key_word_recommendations_hash[e.content] = (e.survey_ids.map { |e| e.to_s }).select { |e| !exclude_survey_ids.include?(e) }
		end
		return key_word_recommendations_hash
	end
end
