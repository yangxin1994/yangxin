# encoding: utf-8
require 'error_enum'
require 'tool'
require 'securerandom'

class ScaleIssue < Issue
	attr_reader :items, :other_item, :is_rand, :item_num_per_group, :labels, :show_unknown
	attr_writer :items, :other_item, :is_rand, :item_num_per_group, :labels, :show_unknown

	ATTR_NAME_ARY = %w[items other_item is_rand item_num_per_group labels show_unknown]
	ITEM_ATTR_ARY = %w[id content]
	OTHER_ITEM_ATTR_ARY = %w[has_other_item id content]

	ANSWER_TIME = 4

	def initialize
		@items = []
		@is_rand = false
		@show_unknown = false
		@labels = ["不满意", "一般", "满意"]

		input_number = 4
		1.upto(input_number) do |item_index|
			item = {}
			item["id"] = Tool.rand_id
			item["content"] = {"text" => "选项#{Tool.convert_digit(item_index)}",
														"image" => [], "audio" => [], "video" => []}
			@items << item
		end
		@other_item = {"has_other_item" => false, "id" => Tool.rand_id, "content" => {"text" => "其他（请填写）：", "image" => [], "video" => [], "audio" => []}}
	end

	def update_issue(issue_obj)
		issue_obj["items"] ||= []
		issue_obj["items"].each do |item_obj|
			item_obj.delete_if { |k, v| !ITEM_ATTR_ARY.include?(k) }
		end
		issue_obj["other_item"] ||= {}
		issue_obj["other_item"].delete_if { |k, v|  !OTHER_ITEM_ATTR_ARY.include?(k)}
		issue_obj["other_item"]["has_other_item"] = issue_obj["other_item"]["has_other_item"].to_s == "true"
		super(ATTR_NAME_ARY, issue_obj)
	end

	def remove_hidden_items(items)
		return if items.blank?
		self.items.delete_if { |item| items["items"].include?(item["id"]) } if !items["items"].blank?
	end

	def estimate_answer_time
		text_length = 0
		self.items.each do |item|
			text_length = text_length + item["content"]["text"].length
		end
		text_length = text_length + self.other_item["content"]["text"] if !self.other_item.nil? && self.other_item["has_other_item"] == true
		return text_length / OOPSDATA[RailsEnv.get_rails_env]["words_per_second"].to_i + ANSWER_TIME
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
