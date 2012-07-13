require 'error_enum'
#The question object has the following structure
# {
#	 "question_id" : id of the question(string),
#	 "question_type" : type of the question(string),
#	 "content" : content of the question(string),
#	 "note" : note of the question(string),
#	 "is_required" : whether the question is required to be answered(bool),
#	 other fields are related to question type
#	}
#Structure of different type question object can be found at ChoiceQuestion, MatrixChoiceQuestion, TextBlankQuestion, NumberBlankQuestion, EmailBlankQuestion, PhoneBlankQuestion, TimeBlankQuestion, AddressBlankQuestion, BlankQuestion, MatrixBlankQuestion, RankQuestion, SortQuestion, ConstSumQuestion
class QualityControlQuestion < BasicQuestion
	include Mongoid::Document
	field :is_required, :type => Boolean, default: true

	before_save :clear_question_object
	before_update :clear_question_object
	before_destroy :clear_question_object

	OBJECTIVE = 0
	MATCHING = 1

	ATTR_NAME_ARY = BasicQuestion::ATTR_NAME_ARY + %w[is_required]

	def self.create_question(question_type)
		question = Question.new
		issue = Object::const_get(ISSUE_TYPE[question_type.to_i]).new
		question.issue = issue.serialize
		question.save
		return question
	end

	#*description*: update the current question instance without generating id for inputs, and without saving (such stuff should be done by methods in subclasses)
	#
	#*params*:
	#* the array of names
	#* the question object
	#
	#*retval*:
	def update_question(attr_name_ary, question_obj)
		attr_name_ary.each do |attr_name|
			next if attr_name == "question_type"
			method_obj = self.method("#{attr_name}=".to_sym)
			method_obj.call(Marshal.load(Marshal.dump(question_obj[attr_name]))) 
		end
	end

	def clone
		return Marshal.load(Marshal.dump(self))
	end

	def new_quality_control_question(question_control_type, question_type, question_number, creator)
		return ErrorEnum::UNAUTHORIZED if !creator.is_admin
		if question_control_type == OBJECTIVE
			question = Object::const_get(question_type).new(:input_prefix => "objective_")
			return [Question.get_question_object(question._id), QualityControlQuestionAnswer.initialize_answer_object(question._id, quality_control_type, question_type)]
		elsif question_control_type == MATCHING
			matching_questions_obj = []
			1.upto(question_number.to_).each do
				question = Object::const_get(question_type).new(:input_prefix => "matching_")
				matching_questions_obj << Question.get_question_object(question._id)
			end
			questions_id_ary = matching_questions_obj.map {|qs_obj| qs_obj["question_id"]}
			MatchingQuestion.create_matching(questions_id_ary)
			return matching_questions_obj << QualityControlQuestionAnswer.initialize_answer_object(questions_id_ary, quality_control_type, question_type)
		else
			return ErrorEnum::WRONG_QUALITY_CONTROL_TYPE
		end
	end

	def update_quality_control_question(question_obj, operator)
		return ErrorEnum::UNAUTHORIZED if !operator.is_admin
		question.update_question(question_obj)

		# some inputs of this question might be removed, remove these inputs answers in the answer document
		QualityControlQuestionAnswer.check_and_clear_inputs(self)

		return retval if retval != true
		question.clear_question_object
		return Question.get_question_object(question._id)
	end

	def self.list_quality_control_question(quality_control_type, operator)
		return ErrorEnum::UNAUTHORIZED if !operator.is_admin

		questions_obj_ary = []
		if quality_control_type == OBJECTIVE
			question_obj_ary = Question.objective_quality_control_questions.to_a.map {|q| Question.get_question_object(q._id)}
		elsif quality_control_type == MATCHING
			questions_id = Question.matching_quality_control_questions.to_a.map {|q| q._id}
			while questions_id.length > 0
				q_id = questions_id.pop
				matching_question_ids = MatchingQuestion.get_matching_question_ids(q_id)
				questions_obj_ary << matching_question_ids.map {|temp_q_id| Question.get_question_object(temp_q_id)}
				matching_question_ids.each do |temp_q_id|
					questions_id.delete(temp_q_id)
				end
			end
		else
			return ErrorEnum::WRONG_QUALITY_CONTROL_TYPE
		end
		return questions_obj_ary
	end

	def show_quality_control_question(operator)
		return ErrorEnum::UNAUTHORIZED if !operator.is_admin
		if self.input_prefix = "objective_"
			question_obj = Question.get_question_object(self._id)
			answer = Answer.find_by_question_id(self._id)[0]
			return [question_obj, answer.serialize]
		elsif self.input_prefix = "matching_"
			matching_question_ids = MatchingQuestion.get_matching_question_ids(self._id)
			question_obj_ary = matching_question_ids.map {|q_id| Question.get_question_object(q_id)}
			answer = Answer.find_by_question_id(self._id)[0]
			return [question_obj, answer.serialize]
		else
			return ErrorEnum::WRONG_QUALITY_CONTROL_TYPE
		end
	end

	def delete_quality_control_question(operator)
		return ErrorEnum::UNAUTHORIZED if !operator.is_admin
		if self.input_prefix = "objective_"
			QualityControlQuestionAnswer.destroy_by_question_id(self._id)
			self.status = -1
			self.save
		elsif self.input_prefix = "matching_"
			matching_question_ids = MatchingQuestion.get_matching_question_ids(self._id)
			matching_question_ids.each do |q_id|
				question = Question.find_by_id(q_id)
				QualityControlQuestionAnswer.destroy_by_question_id(question._id)
				if !question.nil?
					question.status = -1
					question.save
				end
			end
		else
			return ErrorEnum::WRONG_QUALITY_CONTROL_TYPE
		end
	end
end
