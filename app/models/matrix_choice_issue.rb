# encoding: utf-8
require 'error_enum'
require 'tool'
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

	attr_reader :choices, :choice_num_per_row, :min_choice, :max_choice, :show_style, :is_rand, :row_id, :row_name, :is_row_rand, :row_num_per_group
	attr_writer :choices, :choice_num_per_row, :min_choice, :max_choice, :show_style, :is_rand, :row_id, :row_name, :is_row_rand, :row_num_per_group

	ATTR_NAME_ARY = %w[choices choice_num_per_row min_choice max_choice show_style is_rand row_id row_name is_row_rand row_num_per_group]
	CHOICE_ATTR_ARY = %w[input_id content is_exclusive]

	def initialize
		@choice_num_per_row = -1
		@min_choice = 1
		@max_choice = 1
		@show_style = 0
		@is_rand = false	
		@row_name = []	
		@row_id = []	
		@is_row_rand = false	
		@row_num_per_group = -1	
		@choices = []
		1.upto(4) do |row_id|
			@row_id << row_id
			@row_name << "子题目#{Tool.convert_digit(row_id)}"
		end
		1.upto(4) do |input_index|
			choice = {}
			choice["input_id"] = input_index
			choice["content"] = {"text" => "选项#{Tool.convert_digit(input_index)}",
														"image" => [], "audio" => [], "video" => []}
			choice["is_exclusive"] = true
			@choices << choice
		end
	end

	def update_issue(issue_obj)
		issue_obj["choices"] ||= []
		issue_obj["choices"].each do |choice_obj|
			choice_obj.delete_if { |k, v| !CHOICE_ATTR_ARY.include?(k) }
			choice_obj["is_exclusive"] = choice_obj["is_exclusive"].to_s == "true"
		end
		issue_obj["choice_num_per_row"] = issue_obj["choice_num_per_row"].to_i
		issue_obj["min_choice"] = issue_obj["min_choice"].to_i
		issue_obj["max_choice"] = issue_obj["max_choice"].to_i
		issue_obj["row_num_per_group"] = issue_obj["row_num_per_group"].to_i
		issue_obj["show_style"] = issue_obj["show_style"].to_i
		issue_obj["is_rand"] = issue_obj["is_rand"].to_s == "true"
		issue_obj["is_row_rand"] = issue_obj["is_row_rand"].to_s == "true"
		super(ATTR_NAME_ARY, issue_obj)
	end

	def remove_hidden_items(items, sub_questions)
		self.choices.delete_if { |choice| items.include?(choice["input_id"]) }
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
