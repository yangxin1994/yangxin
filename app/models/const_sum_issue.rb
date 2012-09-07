# encoding: utf-8
require 'error_enum'
require 'tool'
require 'securerandom'
#Besides the fields that all types questions have, const sum questions also have:
# {
#	 "items" : array of items(array),
#	 "is_rand" : whether randomly show blanks(bool)
#	 "sum" : sum value(int)
#	}
#The element in the "item" array has the following structure
# {
#	 "item_id": id of the input
#  "content": content of the item(string),
#  "has_input": whether there is a input text field(bool)
# }
class ConstSumIssue < Issue

	attr_reader :items, :other_item, :is_rand, :sum
	attr_writer :items, :other_item, :is_rand, :sum

	ATTR_NAME_ARY = %w[items other_item is_rand sum]
	ITEM_ATTR_ARY = %w[input_id content]
	OTHER_ITEM_ATTR_ARY = %w[has_other_item input_id content]

	def initialize
		@items = []
		@is_rand = false
		@sum = 100
		@other_item = {"has_other_item" => false}

		1.upto(4) do |item_index|
			item = {}
			item["input_id"] = item_index
			item["content"] = {"text" => "选项#{Tool.convert_digit(item_index)}",
														"image" => [], "audio" => [], "video" => []}
			@items << item
		end
	end

	def update_issue(issue_obj)
		issue_obj ||= []
		issue_obj["items"].each do |item_obj|
			item_obj.delete_if { |k, v| !ITEM_ATTR_ARY.include?(k) }
		end
		issue_obj["sum"] = issue_obj["sum"].to_i
		issue_obj["other_item"] ||= {}
		issue_obj["other_item"].delete_if { |k, v|  !OTHER_ITEM_ATTR_ARY.include?(k)}
		issue_obj["other_item"]["has_other_item"] = issue_obj["other_item"]["has_other_item"].to_s == "true"
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
