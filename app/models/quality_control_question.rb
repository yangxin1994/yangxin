require 'error_enum'
#The quality control question object has the following structure
# {
#	 "question_id" : id of the question, must start by "quality_control_"(string),
#	 "content" : content of the question(string),
#	 "question_type" : content of the question, either 0 (for objective questions) or 1 (for matching questions)(string),
#	 "creator_email" : email of the creator(string),
#	 "last_mender_email" : email of the last mender(string),
#	 "choices" : array of choice items(array),
#	 "choice_num_per_row" : number of choices items in one row(integer),
#	 "is_list_style" : whether show choices in list style(bool),
#	 "matching_question_id" : the quality control question id that matches this question. If set as "", this question is an objective quality control question(string),
#	 "answer_choice_id" : the choice id of the correct answer for objective quality control question. If set as "", this is a matching question(string)
#	}
class QualityControlQuestion
	include Mongoid::Document

	field :question_id, :type => String, default: -> { "quality_control_#{SecureRandom.uuid}" }
	field :content, :type => String, default: OOPSDATA["question_default_settings"]["content"]
	field :question_type, :type => Integer, default: 0
	field :creator_email, :type => String, default: ""
	field :last_mender_email, :type => String, default: ""
	field :choices, :type => Array, default: []
	field :choice_num_per_row, :type => Integer, default: -1
	field :is_list_style, :type => Boolean, default: true
	field :matching_question_id, :type => String, default: ""
	field :answer_choice_id, :type => String, default: ""
	scope :objective_questions, lambda { where(:question_type => OBJECTIVE_QUESTION) }
	scope :matching_questions, lambda { where(:question_type => MATCHING_QUESTION) }

	CHOICE_ATTR_ARY = %w[choice_id content]

	OBJECTIVE_QUESTION  = 0
	MATCHING_QUESTION = 1

	before_save :clear_question_object
	before_update :clear_question_object
	before_destroy :clear_question_object

	def self.create_objective_question(creator)
		return ErrorEnum::UNAUTHORIZED if !creator.is_admin

		question = QualityControlQuestion.new(:creator_email => creator.email, :question_type => OBJECTIVE_QUESTION)
		question.save
		return QualityControlQuestion.get_question_object(question.question_id)
	end

	def self.create_matching_questions(creator)
		return ErrorEnum::UNAUTHORIZED if !creator.is_admin

		question_1 = QualityControlQuestion.new(:creator_email => creator.email, :question_type => MATCHING_QUESTION)
		question_2 = QualityControlQuestion.new(:creator_email => creator.email, :question_type => MATCHING_QUESTION)

		question_1.matching_question_id = question_2.question_id
		question_2.matching_question_id = question_1.question_id

		question_1.save
		question_2.save

		return [QualityControlQuestion.get_question_object(question_1.question_id), QualityControlQuestion.get_question_object(question_2.question_id)]
	end

	def update_question(question_obj, last_mender)
		return ErrorEnum::UNAUTHORIZED if !last_mender.is_admin

		if self.question_type == OBJECTIVE_QUESTION
			self.update_objective_question(question_obj, last_mender)
		else
			self.update_matching_questions(question_obj, last_mender)
		end
	end

	def update_objective_question(question_obj, last_mender)
		choice_id_ary = question_obj["choices"].map {|ele| ele["choice_id"]}
		return ErrorEnum::WRONG_QUALITY_CONTROL_QUESTION_ANSWER if !choice_id_ary.include?(question_obj["answer_choice_id"])

		self.content = question_obj["content"]
		self.choice_num_per_row = question_obj["choice_num_per_row"]
		self.is_list_style = question_obj["is_list_style"]
		self.answer_choice_id = question_obj["answer_choice_id"]
		self.choices = Marshal.load(Marshal.dump(question_obj["choices"]))
		self.last_mender_email = last_mender.email

		self.save
		return self.get_question_object
	end

	def update_matching_questions(question_obj_ary, last_mender)
		question_ary = []
		question_ary << QualityControlQuestion.find_by_id(question_obj_ary[0]["question_id"])
		question_ary << QualityControlQuestion.find_by_id(question_obj_ary[1]["question_id"])

		return ErrorEnum::QUALITY_CONTROL_QUESTION_NOT_EXIST if question_ary[0].nil? || question_ary[1].nil?
		return ErrorEnum::QUALITY_CONTROL_QUESTION_NOT_MATCH if question_ary[0].matching_question_id != question_ary[1].question_id
		return ErrorEnum::WRONG_QUALITY_CONTROL_QUESTION_ANSWER if question_obj_ary[0]["choices"].length != question_obj_ary[1]["choices"].length

		new_question_obj_ary = []
		question_ary.each_with_index do |question, index|
			question.content = question_obj_ary[index]["content"]
			question.choice_num_per_row = question_obj_ary[index]["choice_num_per_row"]
			question.is_list_style = question_obj_ary[index]["is_list_style"]
			question.answer_choice_id = question_obj_ary[index]["answer_choice_id"]
			question.choices = Marshal.load(Marshal.dump(question_obj_ary[index]["choices"]))
			question.last_mender_email = last_mender.email
			question.save
			new_question_obj_ary << question.get_question_object
		end
		
		return new_question_obj_ary
	end

	def show(operator)
		return ErrorEnum::UNAUTHORIZED if !operator.is_admin

		if self.question_type == OBJECTIVE_QUESTION
			self.show_objective_question
		else
			self.show_matching_questions
		end
	end
	
	def show_objective_question
		return ErrorEnum::QUALITY_CONTROL_QUESTION_NOT_EXIST if self.nil?
		return ErrorEnum::WRONG_QUALITY_CONTROL_QUESTION_TYPE if self.question_type != OBJECTIVE_QUESTION
		return self.get_question_object
	end

	def show_matching_questions
		return ErrorEnum::QUALITY_CONTROL_QUESTION_NOT_EXIST if self.nil?
		return ErrorEnum::WRONG_QUALITY_CONTROL_QUESTION_TYPE if self.question_type != MATCHING_QUESTION
		question_2_id = self.matching_question_id
		question_2 = QualityControlQuestion.find_by_id(question_2_id)
		return ErrorEnum::QUALITY_CONTROL_QUESTION_NOT_EXIST if question_2.nil?
		return [self.get_question_object, question_2.get_question_object]
	end

	def self.list_objective_questions(operator)
		return ErrorEnum::UNAUTHORIZED if !operator.is_admin

		objective_questions = QualityControlQuestion.objective_questions
		objective_questions_obj_ary = []
		objective_questions.each do |q|
			objective_questions_obj_ary << q.get_question_object
		end
	end

	def self.list_matching_questions(operator)
		return ErrorEnum::UNAUTHORIZED if !operator.is_admin

		matching_questions = QualityControlQuestion.matching_questions.to_a

		matching_questions_obj_ary = []
		while matching_questions.length > 0
			question_1 = matching_questions.pop
			question_2_id = question_1.matching_question_id
			question_2 = QualityControlQuestion.find_by_id(question_2_id)
			next if question_2 == nil
			matching_questions_obj_ary << [question_1.get_question_object, question_2.get_question_object]
			matching_questions.delete_if {|q| q.question_id == question_2_id}
		end
		return matching_questions_obj_ary
	end

	def delete(operator)
		return ErrorEnum::UNAUTHORIZED if !operator.is_admin

		if self.question_type == OBJECTIVE_QUESTION
			self.delete_objective_question
		else
			self.delete_matching_questions
		end
	end

	def delete_objective_question
		return ErrorEnum::WRONG_QUALITY_CONTROL_QUESTION_TYPE if self.question_type != OBJECTIVE_QUESTION
		return self.destroy
	end

	def delete_matching_questions
		question_2 = QualityControlQuestion.find_by_id(self.matching_question_id)
		return ErrorEnum::WRONG_QUALITY_CONTROL_QUESTION_TYPE if !self.nil? && self.question_type != MATCHING_QUESTION
		return ErrorEnum::WRONG_QUALITY_CONTROL_QUESTION_TYPE if !question_2.nil? && question_2.question_type != MATCHING_QUESTION
		if !question_2.nil?
			return ErrorEnum::QUALITY_CONTROL_QUESTION_NOT_MATCH if self.matching_question_id != question_2.question_id
			self.destroy
			question_2.destroy
			return true
		else
			matching_question_id = self.matching_question_id
			return ErrorEnum::QUALITY_CONTROL_QUESTION_NOT_MATCH if !QualityControlQuestion.find_by_id(matching_question_id).nil?
			return self.destroy
		end
	end

	#*description*: find the question instance by its id, return nil if the question does not exist
	#
	#*params*:
	#* id of the question required
	#
	#*retval*:
	#* the question instance
	def self.find_by_id(question_id)
		return QualityControlQuestion.where(:question_id => question_id)[0]
	end

	#*description*: serialize the current instance into a question object
	#
	#*params*:
	#* the array of names
	#
	#*retval*:
	#* the question object
	def serialize
		question_obj = {}
		question_obj["question_id"] = self.question_id.to_s
		question_obj["content"] = self.content
		question_obj["choice_num_per_row"] = self.choice_num_per_row
		question_obj["is_list_style"] = self.is_list_style
		question_obj["matching_question_id"] = self.matching_question_id
		question_obj["answer_choice_id"] = self.answer_choice_id
		question_obj["question_type"] = self.question_type
		question_obj["creator_email"] = self.creator_email
		question_obj["last_mender_email"] = self.last_mender_email
		question_obj["choices"] = Marshal.load(Marshal.dump(self.choices))
		return question_obj
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
			question = QualityControlQuestion.find_by_id(question_id)
			return ErrorEnum::QUALITY_CONTROL_QUESTION_NOT_EXIST if question == nil
			question_object = question.serialize
			Cache.write(question_id, question_object)
		end
		return question_object
	end

	def get_question_object
		question_object = Cache.read(self.question_id)
		if question_object == nil
			question_object = self.serialize
			Cache.write(question_id, question_object)
		end
		return question_object
	end

	#*description*: clear the cached question object corresponding to current instance, usually called when the question is updated, either its meta data, or questions and constrains
	#
	#*params*:
	def clear_question_object
		Cache.write(self.question_id, nil)
	end

end
