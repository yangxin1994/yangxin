# coding: utf-8
require 'error_enum'
require 'quality_control_type_enum'
class Question < BasicQuestion
	include Mongoid::Document
	field :is_required, :type => Boolean, default: true

	before_save :clear_question_object
	before_update :clear_question_object
	before_destroy :clear_question_object

	def self.create_question(question_type)
		return ErrorEnum::WRONG_QUESTION_TYPE if !self.has_question_type(question_type)
		question = Question.new
		issue = Issue.create_issue(question_type)
		question.issue = issue.serialize
		question.question_type = question_type
		if question_type == QuestionTypeEnum::PARAGRAPH
			question.content = {"text" => "请在此输入文本描述", "image" => "", "audio" => "", "video" => ""}
		end
		question.save
		return question
	end

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

	def estimate_answer_time
		text_length = self.content["text"].length + self.note.length
		return (text_length / OOPSDATA[RailsEnv.get_rails_env]["words_per_second"].to_i).ceil + 
			Issue.create_issue(self.question_type, self.issue).estimate_answer_time
	end

	def serialize
		question_obj = {}
		question_obj["_id"] = self._id.to_s
		question_obj["content"] = self.content
		question_obj["note"] = self.note
		question_obj["question_type"] = self.question_type
		question_obj["is_required"] = self.is_required
		question_obj["issue"] = Marshal.load(Marshal.dump(self.issue))
		question_obj["type"] = self._type
		return question_obj
	end
end