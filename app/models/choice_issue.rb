# encoding: utf-8
require 'error_enum'
require 'tool'
require 'securerandom'
#Besides the fields that all types questions have, choice questions also have:
# {
#	 "choices" : array of choice items(array),
#	 "choice_num_per_row" : number of choices items in one row(integer),
#	 "min_choice" : number of choices that user at least selects(integer),
#	 "max_choice" : number of choices that user at most selects(integer),
#	 "is_list_style" : whether show choices in list style(bool),
#	 "is_rand" : whether randomly show choices(bool),
#	}
#The element in the "choices" array has the following structure
# {
#  "choice_id": the id of this choice input
#  "content": the content of the choice(string),
#  "is_exclusive": whether this choice item is exclusive(bool)
# }
class ChoiceIssue < Issue

	attr_reader :items, :other_item, :choice_num_per_row, :min_choice, :max_choice, :option_type, :is_list_style, :is_rand
	attr_writer :items, :other_item, :choice_num_per_row, :min_choice, :max_choice, :option_type, :is_list_style, :is_rand

	ATTR_NAME_ARY = %w[items other_item choice_num_per_row min_choice max_choice option_type is_list_style is_rand]
	CHOICE_ATTR_ARY = %w[input_id content is_exclusive]
	OTHER_ITEM_ATTR_ARY = %w[has_other_item input_id content is_exclusive]

	def initialize
		@choice_num_per_row = -1
		@min_choice = 1
		@max_choice = 1
		@option_type = 1
		@is_list_style = true
		@is_rand = false	
		@items = []
		input_number = 4
		1.upto(input_number) do |input_index|
			choice = {}
			choice["input_id"] = input_index
			choice["content"] = {"text" => "选项#{Tool.convert_digit(input_index)}",
														"image" => [], "audio" => [], "video" => []}
			choice["is_exclusive"] = false
			@items << choice
		end
		@other_item = {"has_other_item" => false, "input_id" => input_number + 1, "content" => {"text" => "其他（请填写）：", "image" => [], "video" => [], "audio" => []}, "is_exclusive" => false}
	end

	def update_issue(issue_obj)
		issue_obj["items"] ||= []
		issue_obj["items"].each do |choice_obj|
			choice_obj.delete_if { |k, v| !CHOICE_ATTR_ARY.include?(k) }
			choice_obj["is_exclusive"] = choice_obj["is_exclusive"].to_s == "true"
		end
		issue_obj["choice_num_per_row"] = issue_obj["choice_num_per_row"].to_i
		issue_obj["min_choice"] = issue_obj["min_choice"].to_i
		issue_obj["max_choice"] = issue_obj["max_choice"].to_i
		issue_obj["option_type"] = issue_obj["option_type"].to_i
		issue_obj["is_list_style"] = issue_obj["is_list_style"].to_s == "true"
		issue_obj["is_rand"] = issue_obj["is_rand"].to_s == "true"
		issue_obj["other_item"] ||= {}
		issue_obj["other_item"].delete_if { |k, v|  !OTHER_ITEM_ATTR_ARY.include?(k)}
		issue_obj["other_item"]["has_other_item"] = issue_obj["other_item"]["has_other_item"].to_s == "true"
		super(ATTR_NAME_ARY, issue_obj)
	end

	def remove_hidden_items(items)
		return if items.blank?
		self.items.delete_if { |choice| items["items"].include?(choice["input_id"]) } if !items["items"].blank?
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
