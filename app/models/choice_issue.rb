require 'error_enum'
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

	attr_reader :choices, :other_item, :choice_num_per_row, :min_choice, :max_choice, :option_type, :is_list_style, :is_rand
	attr_writer :choices, :other_item, :choice_num_per_row, :min_choice, :max_choice, :option_type, :is_list_style, :is_rand

	ATTR_NAME_ARY = %w[choices other_item choice_num_per_row min_choice max_choice option_type is_list_style is_rand]
	CHOICE_ATTR_ARY = %w[input_id content is_exclusive]
	OTHER_ITEM_ATTR_ARY = %w[has_other_item input_id content is_exclusive]

	def initialize
		@choice_num_per_row = -1
		@min_choice = 1
		@max_choice = 1
		@option_type = 1
		@is_list_style = true
		@is_rand = false	
		@choices = []
		@other_item = {"has_other_item" => false}
	end

	def update_issue(issue_obj)
		if issue_obj["choices"]
			issue_obj["choices"].each do |choice_obj|
				choice_obj.delete_if { |k, v| !CHOICE_ATTR_ARY.include?(k) }
				choice_obj["is_exclusive"] = choice_obj["is_exclusive"].to_s == "true"
			end
		end
		issue_obj["other_item"].delete_if { |k, v|  !OTHER_ITEM_ATTR_ARY.include?(k)}
		issue_obj["choice_num_per_row"] = issue_obj["choice_num_per_row"].to_i
		issue_obj["min_choice"] = issue_obj["min_choice"].to_i
		issue_obj["max_choice"] = issue_obj["max_choice"].to_i
		issue_obj["option_type"] = issue_obj["option_type"].to_i
		issue_obj["is_list_style"] = issue_obj["is_list_style"].to_s == "true"
		issue_obj["is_rand"] = issue_obj["is_rand"].to_s == "true"
		issue_obj["other_item"]["has_other_item"] = issue_obj["other_item"]["has_other_item"].to_s == "true"
		super(ATTR_NAME_ARY, issue_obj)
	end

	def remove_hidden_items(items, sub_questions)
		self.choices.delete_if { |choice| items.include?(choice["input_id"]) }
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
