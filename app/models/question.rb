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
class Question < BasicQuestion
	include Mongoid::Document
	field :is_required, :type => Boolean, default: true

	before_save :clear_question_object
	before_update :clear_question_object
	before_destroy :clear_question_object

	OBJECTIVE = 0
	MATCHING = 1

	ATTR_NAME_ARY = BasicQuestion::ATTR_NAME_ARY + %w[is_required]

	def self.create_question(question_type)
		return ErrorEnum::WRONG_QUESTION_TYPE if !self.has_question_type(question_type)
		question = Question.new
		issue = Issue.create_issue(question_type)
		question.issue = issue.serialize
		question.question_type = question_type
		temp = question.save
		return question
	end

	#*description*: update the current question instance without generating id for inputs, and without saving (such stuff should be done by methods in subclasses)
	#
	#*params*:
	#* the array of names
	#* the question object
	#
	#*retval*:
	def update_question(question_obj)
		self.content = question_obj["content"]
		self.note = question_obj["note"]
		self.is_required = question_obj["is_required"]
		issue = Issue.create_issue(self.question_type, question_obj["issue"])
		return ErrorEnum::WRONG_DATA_TYPE if issue == ErrorEnum::WRONG_DATA_TYPE
		self.issue = issue.serialize
		self.save
		return self
	end

	def clone
		cloned_question = Question.create_question(self.question_type)
		cloned_question.update_question(self.serialize)
		return cloned_question
	end

	def serialize
		question_obj = {}
		question_obj["_id"] = self._id.to_s
		question_obj["content"] = self.content
		question_obj["note"] = self.note
		question_obj["question_type"] = self.question_type
		question_obj["is_required"] = self.is_required
		question_obj["issue"] = Marshal.load(Marshal.dump(self.issue))
		return question_obj
	end
end
