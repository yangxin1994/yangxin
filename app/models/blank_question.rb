require 'error_enum'
require 'securerandom'
#Besides the fields that all types questions have, blank questions also have:
# {
#	 "inputs" : array of input items(array),
#	 "is_rand" : whether randomly show blanks(bool)
#	}
#The element in the "inputs" array has the following structure
# {
#  "input_id": id of the input(string)
#  "label": label of the input(string),
#  "data_type": can be short_text, long_text, pwd, int, float, email, date, phone, address(string)
# }
class BlankQuestion < Question
	field :question_type, :type => String, default: "BlankQuestion"
	field :inputs, :type => Array, default: []
	field :is_rand, :type => Boolean, default: false

	ATTR_NAME_ARY = Question::ATTR_NAME_ARY + %w[question_type inputs is_rand]
	INPUT_ATTR_ARY = %w[input_id label data_type]

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
		question_obj["inputs"].each do |input_obj|
			input_obj.delete_if { |k, v| !INPUT_ATTR_ARY.include?(k) }
		end
		super(ATTR_NAME_ARY, question_obj)
		self.inputs.each do |input|
			input["input_id"] = SecureRandom.uuid if input["input_id"].to_s == ""
		end
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
		new_inst.inputs.each do |input|
			input["input_id"] = SecureRandom.uuid
		end
		return new_inst
	end

end
