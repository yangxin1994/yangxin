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
class Question
	include Mongoid::Document
	field :content, :type => String, default: OOPSDATA["question_default_settings"]["content"]
	field :note, :type => String, default: OOPSDATA["question_default_settings"]["note"]
	field :is_required, :type => Boolean, default: true
	field :input_prefix, :type => String, default: ""
	field :status, :type => Integer, default: 0
	scope :objective_quality_control_questions, lambda { where(:input_prefix => "objective_", :status => 0) }
	scope :matching_quality_control_questions, lambda { where(:input_prefix => "matching_", :status => 0) }

	before_save :clear_question_object
	before_update :clear_question_object
	before_destroy :clear_question_object

	OBJECTIVE = 0
	MATCHING = 1

	ATTR_NAME_ARY = %w[content note is_required]

	QUESTION_TYPE = %w[ChoiceQuestion MatrixChoiceQuestion TextBlankQuestion NumberBlankQuestion EmailBlankQuestion PhoneBlankQuestion TimeBlankQuestion AddressBlankQuestion BlankQuestion MatrixBlankQuestion ConstSumQuestion SortQuestion RankQuestion Paragraph FileQuestion TableQuestion]

	def self.has_question_type(question_type)
		return QUESTION_TYPE.include?(question_type)
	end

	#*description*: find the question instance by its id, return nil if the question does not exist
	#
	#*params*:
	#* id of the question required
	#
	#*retval*:
	#* the question instance
	def self.find_by_id(question_id)
		return Question.where(:_id => question_id, :statusl => 0)[0]
	end

	#*description*: judge whether this question is a quality control question
	#
	#*params*:
	#
	#*retval*:
	#* boolean value
	def is_quality_control_question
		return ["objective", "matching"].include?(self.input_prefix)
	end

	#*description*: serialize the current instance into a question object
	#
	#*params*:
	#* the array of names
	#
	#*retval*:
	#* the question object
	def serialize(attr_name_ary)
		question_obj = {}
		question_obj["question_id"] = self._id.to_s
		attr_name_ary.each do |attr_name|
			method_obj = self.method("#{attr_name}".to_sym)
			question_obj[attr_name] = Marshal.load(Marshal.dump(method_obj.call()))
		end
		return question_obj
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

	#*description*: get a question object. Will first try to get it from cache. If failed, will get it from database and write cache
	#
	#*params*:
	#* id of the question required
	#
	#*retval*:
	#* the question object: if successfully obtained
	#* ErrorEnum ::QUESTION_NOT_EXIST : if cannot find the question
	def self.get_question_object(question_id)
		question_object = Cache.read(question_id)
		if question_object == nil
			question = Question.find_by_id(question_id)
			return ErrorEnum::QUESTION_NOT_EXIST if question == nil
			question_object = question.serialize
			Cache.write(question_id, question_object)
		end
		return question_object
	end

	#*description*: clear the cached question object corresponding to current instance, usually called when the question is updated, either its meta data, or questions and constrains
	#
	#*params*:
	def clear_question_object
		Cache.write(self._id, nil)
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
