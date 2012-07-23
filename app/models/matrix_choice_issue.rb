require 'error_enum'
require 'securerandom'
#Besides the fields that all types questions have, matrix choice questions also have:
# {
#	 "choices" : array of choice items(array),
#	 "choice_num_per_row" : number of choices items in one row(integer),
#	 "min_choice" : number of choices that user at least selects(integer),
#	 "max_choice" : number of choices that user at most selects(integer),
#	 "is_list_style" : whether show choices in list style(bool),
#	 "is_rand" : whether randomly show choices(bool),
#	 "row_name" : array of row names(array),
#	 "" : array of row id(array),
#	 "is_row_rand" : whether randomly show rows(bool),
#	 "row_num_per_group" : number of rows in each group(integer)
#	}
#The element in the "choice" array has the following structure
# {
#  "choice_id": the id of this choice input
#  "content": the content of the choice(string),
#  "has_input": whether there is a input field(bool),
#  "is_exclusive": whether this choice item is exclusive(bool)
# }
class MatrixChoiceIssue < Issue

	attr_reader :choices, :choice_num_per_row, :min_choice, :max_choice, :is_list_style, :is_rand, :row_name, :is_row_rand, :row_num_per_group
	attr_writer :choices, :choice_num_per_row, :min_choice, :max_choice, :is_list_style, :is_rand, :row_name, :is_row_rand, :row_num_per_group

	ATTR_NAME_ARY = %w[choices choice_num_per_row min_choice max_choice is_list_style is_rand row_name is_row_rand row_num_per_group]
	CHOICE_ATTR_ARY = %w[input_id content is_exclusive]

	def initialize
		@choice_num_per_row = -1
		@min_choice = 1
		@max_choice = 1
		@is_list_style = true
		@is_rand = false	
		@row_name = []	
		@is_row_rand = false	
		@row_num_per_group = -1	
		@choices = []
	end

	def update_issue(issue_obj)
		issue_obj["choices"].each do |choice_obj|
			choice_obj.delete_if { |k, v| !CHOICE_ATTR_ARY.include?(k) }
		end
		issue_obj["choice_num_per_row"] = issue_obj["choice_num_per_row"].to_i
		issue_obj["min_choice"] = issue_obj["min_choice"].to_i
		issue_obj["max_choice"] = issue_obj["max_choice"].to_i
		issue_obj["row_num_per_group"] = issue_obj["row_num_per_group"].to_i
		super(ATTR_NAME_ARY, issue_obj)
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
end
