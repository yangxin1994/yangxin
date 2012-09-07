# encoding: utf-8
require 'error_enum'
require 'tool'
require 'securerandom'
#Besides the fields that all types questions have, rank questions also have:
# {
#	 "items" : array of items(array),
#	 "is_rand" : whether randomly show blanks(bool)
#	}
#The element in the "items" array has the following structure
# {
#	 "item_id": id of the input
#  "label": label of the item(string),
#  "icon": id of the icon used(string),
#  "icon_num": number of icons(int),
#  "has_input": whether there is a input text field(bool)
#  "has_unknow": whether there is an unknow choice(bool)
#  "desc_ary": array of string to describe the item(array)
# }
class RankIssue < Issue
	attr_reader :items, :other_item, :is_rand, :show_style
	attr_writer :items, :other_item, :is_rand, :show_style

	ATTR_NAME_ARY = %w[items other_item is_rand show_style]
	ITEM_ATTR_ARY = %w[input_id content icon icon_num has_unknow desc_ary]
	OTHER_ITEM_ATTR_ARY = %w[has_other_item input_id content icon icon_num desc_ary]

	def initialize
		@items = []
		@is_rand = false
		@show_style = 0
		@other_item = {"has_other_item" => false}

		1.upto(4) do |item_index|
			item = {}
			item["input_id"] = item_index
			item["content"] = {"text" => "选项#{Tool.convert_digit(item_index)}",
														"image" => [], "audio" => [], "video" => []}
			item["icon"] = ""
			item["icon_num"] = 3
			item["has_unknow"] = false
			item["desc_ary"] = ["不满意", "基本满意", "很满意"]
			@items << item
		end
	end

	def update_issue
		issue_obj["items"].each do |item_obj|
			item_obj.delete_if { |k, v| !ITEM_ATTR_ARY.include?(k) }
			item_obj["icon_num"] = item_obj["icon_num"].to_i if !item_obj["icon_num"].nil?
		end
		issue_obj["other_item"].delete_if { |k, v|  !OTHER_ITEM_ATTR_ARY.include?(k)}
		issue_obj["other_item"]["has_other_item"] = issue_obj["other_item"]["has_other_item"].to_s == "true"
		issue_obj["show_style"] = issue_obj["show_style"].to_i
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
