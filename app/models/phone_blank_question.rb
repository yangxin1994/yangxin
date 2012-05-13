require 'error_enum'
require 'securerandom'
#Besides the fields that all types questions have, phone blank questions also have:
# {
#	 "input_id" : id of the phone input
#	 "phone_type" : 1 for fixed phone number, 2 for mobile number, 3 for both fixed phone number and mobile number
#	}
class PhoneBlankQuestion < Question
	field :question_type, :type => String, default: "PhoneBlankQuestion"
	field :input_id, :type => String, default: -> {SecureRandom.uuid}
	field :phone_type, :type => Integer, default: 3

	ATTR_NAME_ARY = Question::ATTR_NAME_ARY + %w[question_type input_id phone_type]

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
