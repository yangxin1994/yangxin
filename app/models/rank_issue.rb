require 'error_enum'
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
	attr_reader :items, :other_item, :is_rand
	attr_writer :items, :other_item, :is_rand

	ATTR_NAME_ARY = %w[items other_item is_rand]
	ITEM_ATTR_ARY = %w[input_id content icon icon_num has_unknow desc_ary]
	OTHER_ITEM_ATTR_ARY = %w[has_other_item input_id content icon icon_num desc_ary]

	def initialize
		@items = []
		@is_rand = false
		@other_item = {"has_other_item" => false}
	end

	def update_issue
		issue_obj["items"].each do |item_obj|
			item_obj.delete_if { |k, v| !ITEM_ATTR_ARY.include?(k) }
			item_obj["icon_num"] = item_obj["icon_num"].to_i if !item_obj["icon_num"].nil?
		end
		issue_obj["other_item"].delete_if { |k, v|  !OTHER_ITEM_ATTR_ARY.include?(k)}
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
