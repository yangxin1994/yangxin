require 'error_enum'

class MatchingQuestion
	include Mongoid::Document
	field :question_id, :type => String, default: ""
	field :matching_ary, :type => Array, default: []

	def self.find_by_question_id(question_id)
		matching = MatchingQuestion.where(:question_id => question_id).first
		return matching
	end

	def self.create_matching(questions_id_ary)
		questions_id_ary.each do |q_id|
			self.new(:question_id => q_id, :matching_ary => questions_id_ary)
			self.save
		end
	end

	def self.get_matching_question_ids(question_id)
		matching = MatchingQuestion.matchings(question_id)
		return ErrorEnum::MATCING_NOT_EXIST if matching.nil?
		return matching.matching_ary
	end

	def self.matching_question_id_groups
		matching_question_id_groups = []
		MatchingQuestion.each do |ele|
			matching_question_id_groups << ele.matching_ary if !matching_question_id_groups.include?(ele.matching_ary)
		end
	end

end
