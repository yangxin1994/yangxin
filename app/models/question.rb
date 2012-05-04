require 'error_enum'
#The question object has the following structure
# {
#	 "question_id" : id of the question(string),
#	 "question_type" : type of the question(string),
#	 "content" : content of the question(string),
#	 other fields are related to question type
#	}
#Structure of different type question object can be found at ChoiceQuestion, MatrixChoiceQuestion, BlankQuestion, MatrixBlankQuestion, RankQuestion, SortQuestion, ConstSumQuestion
class Question
	include Mongoid::Document
	field :content, :type => String, default: OOPSDATA["question_default_settings"]["content"]

	before_save :clear_question_object
	before_update :clear_question_object
	before_destroy :clear_question_object

	ATTR_NAME_ARY = %w[content]

	#*description*: find the question instance by its id, return nil if the question does not exist
	#
	#*params*:
	#* id of the question required
	#
	#*retval*:
	#* the question instance
	def self.find_by_id(question_id)
		return Question.where(:_id => question_id)[0]
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
		attr_name_ary.each do |attr_name|
			method_obj = self.method("#{attr_name}".to_sym)
			question_obj[attr_name] = method_obj.call() 
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
			method_obj = self.method("#{attr_name}=".to_sym)
			method_obj.call(question_obj[attr_name]) 
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
end
