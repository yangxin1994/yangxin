# encoding: utf-8
require 'error_enum'
require 'securerandom'
#Besides the fields that all types questions have, number blank questions also have:
# {
#	 "input_id" : id of the number input
#	 "precision" : number decimals
#	 "min_value" : minimal value of the number(Float)
#	 "max_value" : maximal value of the number(Float)
#	 "unit" : unit
#	}
class NumberBlankQuestion < Question
	field :question_type, :type => String, default: "NumberBlankQuestion"
	field :input_id, :type => String, default: -> {SecureRandom.uuid}
	field :precision, :type => Integer, default: 0
	field :min_value, :type => Float, default: 0.0
	field :max_value, :type => Float, default: 10.0
	field :unit, :type => String, default: "个"

	ATTR_NAME_ARY = Question::ATTR_NAME_ARY + %w[question_type input_id precision min_value max_value unit]

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
