require 'error_enum'
require 'securerandom'
#Besides the fields that all types questions have, matrix blank questions also have:
# {
#	 "inputs" : array of input items(array),
#	 "is_rand" : whether randomly show blanks(bool),
#	 "row_name" : array of row names(array),
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
class MatrixBlankIssue < Issue

	attr_reader :is_rand, :inputs, :row_id, :row_name, :is_row_rand, :row_num_per_group, :show_style
	attr_writer :is_rand, :inputs, :row_id, :row_name, :is_row_rand, :row_num_per_group, :show_style

	ATTR_NAME_ARY = %w[inputs is_rand row_name is_row_rand row_num_per_group show_style]
	INPUT_ATTR_ARY = %w[input_id content data_type properties]

	DATA_TYPE_ARY = %w[Text Number Phone Email Url Address Time]

	TEXT_PROP_ARY = %w[min_length max_length has_multiple_line size]
	NUMBER_PROP_ARY = %w[precision min_value max_value unit unit_location]
	PHONE_PROP_ARY = %w[phone_type]
	EMAIL_PROP_ARY = %w[]
	ADDRESS_PROP_ARY = %w[has_postcode format]
	TIME_PROP_ARY = %w[format min_time max_time]

	def initialize
		@inputs = []
		@is_rand = false
		@row_name = []
		@is_row_rand = false
		@row_num_per_group = -1
		@show_style
	end

	#*description*: serialize the current instance into a question object
	#
	#*params*:
	#
	#*retval*:
	#* the question object
	def serialize
		super(ATTR_NAME_ARY)
	end

	def remove_hidden_items(items, sub_questions)
		self.inputs.delete_if { |input| items.include?(input["input_id"]) }
		remaining_row_id = []
		remaining_row_name = []
		self.row_id.each_with_index do |r_id, r_index|
			if !sub_questions.include?(r_id)
				remaining_row_id << r_id
				remaining_row_name << row_name[row_index]
			end
		end
		self.row_id = remaining_row_id
		self.row_name = remaining_row_name
	end

	#*description*: update the current question instance, including generate id for new inputs
	#
	#*params*:
	#* the question object
	#
	#*retval*:
	def update_issue(issue_obj)
		issue_obj["inputs"].each do |input_obj|
			input_obj.delete_if { |k, v| !INPUT_ATTR_ARY.include?(k) }
			return ErrorEnum::WRONG_DATA_TYPE if !DATA_TYPE_ARY.include?(input_obj["data_type"])
			if input_obj["properties"].class == Hash
				input_obj["properties"].delete_if { |k, v| !BlankIssue.const_get("#{input_obj["data_type"].upcase}_PROP_ARY".to_sym).include?(k) }
			else
				input_obj["properties"] == Hash.new
			end
			case input_obj["data_type"]
			when Text
				input_obj["properties"]["min_length"] = input_obj["properties"]["min_length"].to_i if !input_obj["properties"]["min_length"].nil?
				input_obj["properties"]["max_length"] = input_obj["properties"]["max_length"].to_i if !input_obj["properties"]["max_length"].nil?
				input_obj["properties"]["size"] = input_obj["properties"]["size"].to_i if !input_obj["properties"]["size"].nil?
				input_obj["properties"]["has_multiple_line"] = input_obj["properties"]["has_multiple_line"].to_s == "true" if !input_obj["properties"]["has_multiple_line"].nil?
			when Number
				input_obj["properties"]["min_value"] = input_obj["properties"]["min_value"].to_i if !input_obj["properties"]["min_value"].nil?
				input_obj["properties"]["max_value"] = input_obj["properties"]["max_value"].to_i if !input_obj["properties"]["max_value"].nil?
				input_obj["properties"]["precision"] = input_obj["properties"]["precision"].to_i if !input_obj["properties"]["precision"].nil?
				input_obj["properties"]["unit_location"] = input_obj["properties"]["unit_location"].to_i if !input_obj["properties"]["unit_location"].nil?
			when Phone
				input_obj["properties"]["phone_type"] = input_obj["properties"]["phone_type"].to_i if !input_obj["properties"]["phone_type"].nil?
			when Address
				input_obj["properties"]["format"] = input_obj["properties"]["format"].to_i if !input_obj["properties"]["format"].nil?
				input_obj["properties"]["has_postcode"] = input_obj["properties"]["has_postcode"].to_s == "true" if !input_obj["properties"]["has_postcode"].nil?
			when Time
				input_obj["properties"]["format"] = input_obj["properties"]["format"].to_i if !input_obj["properties"]["format"].nil?
				input_obj["properties"]["min_time"].map! { |e| e.to_i } if !input_obj["properties"]["min_time"].nil?
				input_obj["properties"]["max_time"].map! { |e| e.to_i } if !input_obj["properties"]["max_time"].nil?
			end
		end
		issue_obj["row_num_per_group"] = issue_obj["row_num_per_group"].to_i
		issue_obj["show_style"] = issue_obj["show_style"].to_i
		issue_obj["is_rand"] = issue_obj["is_rand"].to_s == "true"
		issue_obj["is_row_rand"] = issue_obj["is_row_rand"].to_s == "true"
		super(ATTR_NAME_ARY, issue_obj)
	end
end
