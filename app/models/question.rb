require 'error_enum'
require 'quality_control_type_enum'
#The question object has the following structure
# {
#	 "question_id" : id of the question(string),
#	 "question_type" : type of the question(string),
#	 "content" : content of the question(string),
#	 "note" : note of the question(string),
#	 "is_required" : whether the question is required to be answered(bool),
#	 other fields are related to question type
#	}
#Structure of different type question object can be found at ChoiceQuestion, MatrixChoiceQuestion, TextBlankQuestion, NumberBlankQuestion, EmailBlankQuestion, UrlBlankQuestion, PhoneBlankQuestion, TimeBlankQuestion, AddressBlankQuestion, BlankQuestion, MatrixBlankQuestion, RankQuestion, SortQuestion, ConstSumQuestion
class Question < BasicQuestion
	include Mongoid::Document
	field :is_required, :type => Boolean, default: true
	field :question_class, :type => Integer, default: 0
	field :reference_id, :type => String, default: ""

	before_save :clear_question_object
	before_update :clear_question_object
	before_destroy :clear_question_object

	def self.create_question(question_type)
		return ErrorEnum::WRONG_QUESTION_TYPE if !self.has_question_type(question_type)
		question = Question.new
		issue = Issue.create_issue(question_type)
		question.issue = issue.serialize
		question.question_type = question_type
		question.save
		return question
	end

	def self.create_template_question(template_question)
		question = Question.new(:question_class => 1, :reference_id => template_question._id)
		question.content = template_question.content
		question.note = template_question.note
		question.question_type = template_question.question_type
		question.issue = Marshal.load(Marshal.dump(template_question.issue))
		question.save
		return question
	end

	def convert_template_question_to_normal_question
		self.question_class = 0
		self.reference_id = ""
		return self.save
	end

	def self.create_quality_control_question(quality_control_question)
		questions = []
		if quality_control_question.quality_control_type == QualityControlTypeEnum::OBJECTIVE
			question = Question.new(:question_class => 2, :reference_id => quality_control_question._id.to_s)
			question.content = quality_control_question.content
			question.note = quality_control_question.note
			question.question_type = quality_control_question.question_type
			question.issue = Marshal.load(Marshal.dump(quality_control_question.issue))
			question.save
			questions << question
		else
			quality_control_question_ids = MatchingQuestion.get_matching_question_ids(quality_control_question._id.to_s)
			quality_control_question_ids.each do |quality_control_question_id|
				quality_control_question = QualityControlQuestion.find_by_id(quality_control_question_id)
				question = Question.new(:question_class => 2, :reference_id => quality_control_question_id)
				question.content = quality_control_question.content
				question.note = quality_control_question.note
				question.question_type = quality_control_question.question_type
				question.issue = Marshal.load(Marshal.dump(quality_control_question.issue))
				question.save
				questions << question
			end
		end
		return questions
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

	def remove_hidden_items(items)
		issue = Issue.create_issue(self.question_type, self.issue)
		issue.remove_hidden_items(items)
		self.issue = issue.serialize
		return self
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
