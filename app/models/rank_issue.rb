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
	attr_reader :items, :other_item, :is_rand, :show_style, :icon, :icon_num, :bar, :desc_ary
	attr_writer :items, :other_item, :is_rand, :show_style, :icon, :icon_num, :bar, :desc_ary

	ATTR_NAME_ARY = %w[items other_item is_rand show_style icon icon_num bar desc_ary]
	ITEM_ATTR_ARY = %w[input_id content]
	OTHER_ITEM_ATTR_ARY = %w[has_other_item input_id content]

	def initialize
		@items = []
		@is_rand = false
		@show_style = 0
		@icon = 0
		@icon_num = 7
		@desc_ary = ["不满意", "基本满意", "很满意"]
		@bar = 0

		input_number = 4
		1.upto(input_number) do |item_index|
			item = {}
			item["input_id"] = item_index
			item["content"] = {"text" => "选项#{Tool.convert_digit(item_index)}",
														"image" => [], "audio" => [], "video" => []}
			@items << item
		end
		@other_item = {"has_other_item" => false, "input_id" => input_number + 1, "content" => {"text" => "其他（请填写）：", "image" => [], "video" => [], "audio" => []}}
	end

	def update_issue(issue_obj)
		issue_obj["items"] ||= []
		issue_obj["items"].each do |item_obj|
			item_obj.delete_if { |k, v| !ITEM_ATTR_ARY.include?(k) }
			item_obj["icon_num"] = item_obj["icon_num"].to_i if !item_obj["icon_num"].nil?
		end
		issue_obj["show_style"] = issue_obj["show_style"].to_i
		issue_obj["other_item"] ||= {}
		issue_obj["other_item"].delete_if { |k, v|  !OTHER_ITEM_ATTR_ARY.include?(k)}
		issue_obj["other_item"]["has_other_item"] = issue_obj["other_item"]["has_other_item"].to_s == "true"
		super(ATTR_NAME_ARY, issue_obj)
	end

	def remove_hidden_items(items)
		return if items.blank?
		self.items.delete_if { |item| items["items"].include?(item["input_id"]) } if !items["items"].blank?
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
