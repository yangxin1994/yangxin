require 'error_enum'
require 'securerandom'
#Besides the fields that all types questions have, sort questions also have:
# {
#	 "item" : array of items(array),
#	 "is_rand" : whether randomly show blanks(bool)
#	}
#The element in the "input" array has the following structure
# {
#  "item_id": id of the input
#  "content": content of the item(string),
#  "has_input": whether there is a input text field(bool),
#  "min": minimum number of items needed to be sorted(int),
#  "max": maximum number of items needed to be sorted(int)
# }
class SortIssue < Issue
	attr_reader :items, :other_item, :min, :max, :is_rand
	attr_writer :items, :other_item, :min, :max, :is_rand

	ATTR_NAME_ARY = %w[items other_item is_rand min max]
	ITEM_ATTR_ARY = %w[input_id content]
	OTHER_ITEM_ATTR_ARY = %w[has_other_item input_id content]

	def initialize
		@items = []
		@is_rand = false
		@other_item = {"has_other_item" => false}
	end

	def update_issue(issue_obj)
		issue_obj["items"].each do |item_obj|
			item_obj.delete_if { |k, v| !ITEM_ATTR_ARY.include?(k) }
		end
		issue_obj["other_item"].delete_if { |k, v|  !OTHER_ITEM_ATTR_ARY.include?(k)}
		issue_obj["min"] = issue_obj["min"].to_i if !issue_obj["min"].nil?
		issue_obj["max"] = issue_obj["max"].to_i if !issue_obj["max"].nil?
		super(ATTR_NAME_ARY, issue_obj)
	end

	def remove_hidden_items(items, sub_questions)
		self.items.delete_if { |item| items.include?(item["input_id"]) }
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
