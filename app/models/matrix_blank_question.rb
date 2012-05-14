require 'error_enum'
require 'securerandom'
#Besides the fields that all types questions have, matrix blank questions also have:
# {
#	 "inputs" : array of input items(array),
#	 "is_rand" : whether randomly show blanks(bool),
#	 "row_name" : array of row names(array),
#	 "row_id" : array of row id(array),
#	 "is_row_rand" : whether randomly show rows(bool),
#	 "row_num_per_group" : number of rows in each group(integer)
#	}
#The element in the "inputs" array has the following structure
# {
#  "input_id": id of the input(string)
#  "label": label of the input(string),
#  "data_type": can be Text, Number, Email, Phone, Address, Time
#  "properties": a hash of properties, for different data type, this input has different properties
# }
#The input with Text data type has the following properties
# {
#  "min_length"
#  "max_length"
#  "has_multiple_line"
#  "size"
# }
#The input with Number data type has the following properties
# {
#  "precision"
#  "min_value"
#  "max_value"
#  "unit"
# }
#The input with phone data type has the following properties
# {
#  "phone_type"
# }
#The input with email data type has the following properties
# {
# }
#The input with address data type has the following properties
# {
#  "format"
# }
#The input with time data type has the following properties
# {
#  "format"
# }
class MatrixBlankQuestion < Question
	field :question_type, :type => String, default: "MatrixBlankQuestion"
	field :inputs, :type => Array, default: []
	field :is_rand, :type => Boolean, default: false
	field :row_name, :type => Array, default: []
	field :row_id, :type => Array, default: []
	field :is_row_rand, :type => Boolean, default: false
	field :row_num_per_group, :type => Integer, default: -1

	ATTR_NAME_ARY = Question::ATTR_NAME_ARY + %w[question_type inputs is_rand row_name row_id is_row_rand row_num_per_group]
	INPUT_ATTR_ARY = %w[input_id label data_type properties]

	DATA_TYPE_ARY = %w[Text Number Phone Email Address Time]

	TEXT_PROP_ARY = %w[min_length max_length has_multiple_line size]
	NUMBER_PROP_ARY = %w[precision min_value max_value unit]
	PHONE_PROP_ARY = %w[phone_type]
	EMAIL_PROP_ARY = %w[]
	ADDRESS_PROP_ARY = %w[format]
	TIME_PROP_ARY = %w[format]

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
			return ErrorEnum::WRONG_DATA_TYPE if !DATA_TYPE_ARY.include?(input_obj["data_type"])
			if input_obj["properties"].class == Hash
				input_obj["properties"].delete_if { |k, v| !BlankQuestion.const_get("#{input_obj["data_type"].upcase}_PROP_ARY".to_sym).include?(k) }
			else
				input_obj["properties"] == Hash.new
			end
		end
		super(ATTR_NAME_ARY, question_obj)
		self.inputs.each do |input|
			input["input_id"] = SecureRandom.uuid if input["input_id"].to_s == ""
		end
		self.row_id.each_with_index do |id, index|
			row_id[index] = SecureRandom.uuid if id.to_s == ""
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
		new_inst.row_id.each_with_index do |id, index|
			row_id[index] = SecureRandom.uuid
		end
		return new_inst
	end

end
