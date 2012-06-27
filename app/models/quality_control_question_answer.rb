require 'error_enum'
class QualityControlQuestionAnswer
	include Mongoid::Document

	field :input_id, :type => String, default: ""
	field :question_id, :type => String, default: ""
	field :quality_control_type, :type => Integer, default: 0
	field :question_type, :type => String, default: ""
	field :answer, :type => Hash, default: {}
	scope :answers_of, lambda { |question_id| where(:question_id => "question_id") }

	OBJECTIVE_QUESTION  = 0
	MATCHING_QUESTION = 1

	ANSWER_STRUCTURE = {"0_ChoiceQuestion" => [],
		"0_TextBlankQuestion" => {"fuzzy" => true, "text" => ""},
		"0_NumberBlankQuestion" => {"number" => 0},
		"1_ChoiceQuestion" => []
	}

	def self.find_by_input_id(input_id)
		return self.where(:input_id => input_id)[0]
	end

	def self.find_by_question_id(question_id)
		return self.where(:input_id => question_id)
	end

	def self.initialize_answer_object(question_id, quality_control_type, question_type)
		qc_ans_obj = {}
		qc_ans_obj["question_id"] = question_id
		qc_ans_obj["quality_control_type"] = quality_control_type
		qc_ans_obj["question_type"] = question_type
		qc_ans_obj["answer"] = ANSWER_STRUCTURE["#{quality_control_type}_#{question_type}"]
		return qc_ans_obj
	end

	def self.check_and_clear_inputs(question)
		if question.question_type == "ChoiceQuestion"
			input_id_ary = question.choices.map {|choice| choice["choice_id"]}
		elsif question.quesion_type == "TextBlankQuestion" && question.question_type == "NumberBlankQuestion"
			input_id_ary = [question.input_id]
		end
		answers = self.answers_of(question._id)
		answers.each do |answer|
			answer.destroy if !input_id_ary.include?(answer["input_id"])
		end
	end

	def self.delete_answers_of(question)
		answers = self.answers_of(question._id)
		answers.each do |answer|
			answer.destroy
		end
	end

	def self.update(quality_control_type, question_type, question_id_ary, answer_object, operator)
		return ErrorEnum::UNAUTHORIZED if !operator.is_admin
		# construct the hash, from which the question id for each input can be found easily
		question_id_for_inputs = {}
		question_id_ary.each do |question_id|
			question = Question.find_by_id(question_id)
			return ErrorEnum::QUESTION_NOT_EXIST if !question.nil?
			if question.question_type == "ChoiceQuestion"
				input_id_ary = question.choices.map {|choice| choice["choice_id"]}
				input_id_ary.each do |input_id|
				question_id_for_inputs[input_id] = question_id
				end
			elsif question.quesion_type == "TextBlankQuestion" && question.question_type == "NumberBlankQuestion"
				question_id_for_inputs[question.input_id] = question_id
			end
		end

		if quality_control_type == "0" && (question_type == "TextBlankQuestion" || question_type == "NumberBlankQuestion")
			input_id = answer_object["input_id"]
			QualityControlQuestionAnswer.update_answer(input_id, question_id_for_inputs[input_id], quality_control_type, question_type, answer_object)
		elsif quality_control_type == "0" && question_type == "ChoiceQuestion"
			answer_object["choice_answers"].each do |choice_answer|
				choice_answer["true_answers"].each do |input_id|
					QualityControlQuestionAnswer.update_answer(input_id, question_id_for_inputs[input_id], quality_control_type, question_type, answer_object)
				end
				choice_answer["false_answers"].each do |input_id|
					QualityControlQuestionAnswer.update_answer(input_id, question_id_for_inputs[input_id], quality_control_type, question_type, answer_object)
				end
			end
		elsif quality_control_type == "1" && question_type == "ChoiceQuestion"
			answer_object["matching_inputs_id"].each do |input_id_ary|
				input_id_ary.each do |input_id|
					QualityControlQuestionAnswer.update_answer(input_id, question_id_for_inputs[input_id], quality_control_type, question_type, answer_object)
				end
			end
		else
			return ErrorEnum::WRONG_QUALITY_CONTROL_TYPE
		end
		return true
	end

	# update answer
	def self.update_answer(input_id, question_id, quality_control_type, question_type, answer_object)
		answer = self.find_by_input_id(input_id)
		if answer.nil?
			answer = Answer.new(:input_id => input_id, :question_id => question_id, :quality_control_type => quality_control_type, :question_type => question_type, :answer => answer_object)
			answer.save
		else
			answer.answer = answer_object
			answer.save
		end
	end

	def serialize
		answer_obj = {}
		answer_obj["quality_control_type"] = self.quality_control_type
		if self.quality_control_type == 0
			answer_obj["question_id"] = self.question_id
		else
			answer_obj["question_id"] = MatchingQuestion.get_matching_question_ids(self.question_id)
		end
		answer_obj["question_type"] = self.question_type
		answer_obj["answer"] = self.answer
	end

	def self.destroy_by_question_id(question_id)
		answers = QualityControlQuestionAnswer.find_by_question_id
		answers.each do |ans|
			ans.destroy
		end
	end

end
