require 'error_enum'
require 'securerandom'
#Besides the fields that all types questions have, table blank questions also have:
# {
#	 "inputs" : array of input items(array),
#	 "is_rand" : whether randomly show blanks(bool),
#	}
#The element in the "inputs" array has the following structure
# {
#  "input_id": id of the input(string)
#  "label": label of the input(string),
#  "data_type": can be short_text, long_text, pwd, int, float, email, date, phone, address(string)
# }
class TableIssue < Issue
	attr_reader :inputs, :is_rand
	attr_writer :inputs, :is_rand

	ATTR_NAME_ARY = %w[inputs is_rand]
	INPUT_ATTR_ARY = %w[label data_type properties]

	DATA_TYPE_ARY = %w[Text Number Phone Email Address Time]

	TEXT_PROP_ARY = %w[min_length max_length has_multiple_line size]
	NUMBER_PROP_ARY = %w[precision min_value max_value unit]
	PHONE_PROP_ARY = %w[phone_type]
	EMAIL_PROP_ARY = %w[]
	ADDRESS_PROP_ARY = %w[format]
	TIME_PROP_ARY = %w[format]

	def initialize
		@inputs = []
		@is_rand = false
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
			when Number
				input_obj["properties"]["min_value"] = input_obj["properties"]["min_value"].to_i if !input_obj["properties"]["min_value"].nil?
				input_obj["properties"]["max_value"] = input_obj["properties"]["max_value"].to_i if !input_obj["properties"]["max_value"].nil?
				input_obj["properties"]["precision"] = input_obj["properties"]["precision"].to_i if !input_obj["properties"]["precision"].nil?
			when Phone
				input_obj["properties"]["phone_type"] = input_obj["properties"]["phone_type"].to_i if !input_obj["properties"]["phone_type"].nil?
			when Address
				input_obj["properties"]["format"] = input_obj["properties"]["format"].to_i if !input_obj["properties"]["format"].nil?
			when Time
				input_obj["properties"]["format"] = input_obj["properties"]["format"].to_i if !input_obj["properties"]["format"].nil?
			end
		end
		super(ATTR_NAME_ARY, issue_obj)
	end
end
