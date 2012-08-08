require 'error_enum'
require 'question_type_enum'
class QualityControlQuestionAnswer
	include Mongoid::Document

	field :question_id, :type => Array, default: []
	field :quality_control_type, :type => Integer, default: 0
	field :question_type, :type => String, default: ""
	field :answer_content, :type => Hash, default: {}

	OBJECTIVE_QUESTION  = 0
	MATCHING_QUESTION = 1

	ANSWER_STRUCTURE = {"#{OBJECTIVE_QUESTION}_#{QuestionTypeEnum::CHOICE_QUESTION}" => {"fuzzy" => false, "items" => []},
		"#{OBJECTIVE_QUESTION}_#{QuestionTypeEnum::TEXT_BLANK_QUESTION}" => {"fuzzy" => true, "text" => ""},
		"#{OBJECTIVE_QUESTION}_#{QuestionTypeEnum::NUMBER_BLANK_QUESTION}" => {"number" => 0},
		"#{MATCHING_QUESTION}_#{QuestionTypeEnum::CHOICE_QUESTION}" => {"matching_items" => []}
	}

	def self.create_new(question_id, quality_control_type, question_type)
		answer = QualityControlQuestionAnswer.new
		answer.question_id = question_id.clone
		answer.quality_control_type = quality_control_type
		answer.question_type = question_type
		case "#{quality_control_type}_#{question_type}"
		when "#{OBJECTIVE_QUESTION}_#{QuestionTypeEnum::CHOICE_QUESTION}"
			answer.answer_content = {"fuzzy" => false, "items" => []}
		when "#{OBJECTIVE_QUESTION}_#{QuestionTypeEnum::TEXT_BLANK_QUESTION}"
			answer.answer_content = {"fuzzy" => true, "text" => ""}
		when "#{OBJECTIVE_QUESTION}_#{QuestionTypeEnum::NUMBER_BLANK_QUESTION}"
			answer.answer_content = {"number" => 0}
		when "#{MATCHING_QUESTION}_#{QuestionTypeEnum::CHOICE_QUESTION}"
			answer.answer_content = {"matching_items" => []}
		end
		answer.save
		return answer
	end

	def self.find_by_question_id(question_id)
		answer = QualityControlQuestionAnswer.where(:question_id => question_id).first
		return answer
	end

	def self.destroy_by_question_id(question_id)
		answer = QualityControlQuestionAnswer.find_by_question_id(question_id)
		answer.destroy if !answer.nil?
	end

	def self.update_answers(question_id, quality_control_type, answer_object, operator)
		return ErrorEnum::UNAUTHORIZED if !operator.is_admin
		if quality_control_type == QualityControlTypeEnum::OBJECTIVE
			answer = QualityControlQuestionAnswer.find_by_question_id([question_id])
			return ErrorEnum::QUALITY_CONTROL_QUESTION_ANSWER_NOT_EXIST if answer.nil?
			answer.answer_content = answer_object
			return answer.save
		elsif quality_control_type == QualityControlTypeEnum::MATCHING
			question_id_ary = MatchingQuestion.get_matching_question_ids(question_id)
			answer = QualityControlQuestionAnswer.find_by_question_id(question_id_ary)
			return ErrorEnum::QUALITY_CONTROL_QUESTION_ANSWER_NOT_EXIST if answer.nil?
			answer.answer_content = answer_object
			return answer.save
		else
			return ErrorEnum::WRONG_QUALITY_CONTROL_TYPE
		end
	end
end
