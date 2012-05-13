require 'error_enum'
require 'securerandom'
#Besides the fields that all types questions have, text blank questions also have:
# {
#	 "input_id" : id of the text input
#	 "min_length" : minimal length of the input text(Integer)
#	 "max_length" : maximal length of the input text(Integer)
#	 "has_multipel_line" : whether has multiple lines to input(Boolean)
#	 "size" : size of the input, can be 0(small), 1(middle), 2(big)
#	}
class TextBlankQuestion < Question
	field :question_type, :type => String, default: "TextBlankQuestion"
	field :input_id, :type => String, default: -> {SecureRandom.uuid}
	field :min_length, :type => Integer, default: 1
	field :max_length, :type => Integer, default: 10
	field :has_multiple_line, :type => Boolean, default: false
	field :size, :type => Integer, default: 1

	ATTR_NAME_ARY = Question::ATTR_NAME_ARY + %w[question_type input_id min_length max_length has_multiple_line size]

	#*description*: serialize the current instance into a question object
	#
	#*params*:
	#
	#*retval*:
	#* the question object
	def serialize
		super(ATTR_NAME_ARY)
	end

	#*description*: update the current question instance, including generate id for new inputs
	#
	#*params*:
	#* the question object
	#
	#*retval*:
	def update_question(question_obj)
		super(ATTR_NAME_ARY, question_obj)
		self.save
	end

	#*description*: clone the current question instance, including generate input ids for new instance
	#
	#*params*:
	#
	#*retval*:
	#* the cloned instance
	def clone
		new_inst = super
		new_inst.input_id = SecureRandom.uuid
		return new_inst
	end

end
