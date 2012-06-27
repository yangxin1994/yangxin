require 'error_enum'

class MatchingQuestion
	include Mongoid::Document
	field :question_id, :type => String, default: ""
	field :matching_question_id, :type => String, default: ""
	scope :matchings, lambda { |question_id| where(:question_id => question_id) }

	def self.create_matching(questions_id_ary)
		questions_id_ary.each do |id_1|
			questions_id_ary.each do |id_2|
				self.new(:question_id => id_1, :matching_question_id => id_2) if id_1 != id_2
				self.save
			end
		end
	end

	def self.get_matching_question_ids(question_id)
		matchings = MatchingQuestion.matchings
		matching_question_ids = matchings.map {|matching| matching.matching_question_id }
		matching_question_ids << question_id
		return matching_question_ids
	end

end
