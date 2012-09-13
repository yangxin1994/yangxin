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
class TemplateQuestion < BasicQuestion
	include Mongoid::Document
	field :attribute_name, :type => String, default: ""

	has_many :template_question_answers

	before_save :clear_question_object
	before_update :clear_question_object
	before_destroy :clear_question_object

	def self.find_by_id(question_id)
		return TemplateQuestion.where(:_id => question_id).first
	end

	def self.create_question(question_type, creator)
		return ErrorEnum::UNAUTHORIZED if !creator.is_admin
		return ErrorEnum::WRONG_QUESTION_TYPE if !self.has_question_type(question_type)
		question = TemplateQuestion.new
		issue = Issue.create_issue(question_type)
		question.issue = issue.serialize
		question.question_type = question_type
		question.save
		return question
	end

	def self.list_template_question
		return TemplateQuestion.all.to_a
	end

	#*description*: update the current question instance without generating id for inputs, and without saving (such stuff should be done by methods in subclasses)
	#
	#*params*:
	#* the array of names
	#* the question object
	#
	#*retval*:
	def update_question(question_obj, operator)
		return ErrorEnum::UNAUTHORIZED if !operator.is_admin
		self.content = question_obj["content"]
		self.note = question_obj["note"]
		self.attribute_name = question_obj["attribute_name"]
		issue = Issue.create_issue(self.question_type, question_obj["issue"])
		return ErrorEnum::WRONG_DATA_TYPE if issue == ErrorEnum::WRONG_DATA_TYPE
		self.issue = issue.serialize
		self.save
		return self
	end

	def serialize
		question_obj = {}
		question_obj["_id"] = self._id.to_s
		question_obj["content"] = self.content
		question_obj["note"] = self.note
		question_obj["attribute_name"] = self.attribute_name
		question_obj["question_type"] = self.question_type
		question_obj["issue"] = Marshal.load(Marshal.dump(self.issue))
		return question_obj
	end
end
