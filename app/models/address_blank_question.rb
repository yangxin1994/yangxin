require 'error_enum'
require 'securerandom'
#Besides the fields that all types questions have, address blank questions also have:
# {
#	 "input_id" : id of the address input(String)
#	 "has_postcode" : whether has a postcode input(Boolean)
#	 "format" : format of the input, an integer in the interval of [1, 15]. If converted into a binary number, it has 4 digits, indicating whether this has "province", "city", "county", "detailed address"(Integer)
#	}
class AddressBlankQuestion < Question
	field :question_type, :type => String, default: "AddressBlankQuestion"
	field :input_id, :type => String, default: -> {SecureRandom.uuid}
	field :has_postcode, :type => Integer, default: 1
	field :format, :type => Boolean, default: 15

	ATTR_NAME_ARY = Question::ATTR_NAME_ARY + %w[question_type input_id has_postcode format]

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
