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
	attr_reader :items, :min, :max, :is_rand
	attr_writer :items, :min, :max, :is_rand

	ATTR_NAME_ARY = %w[items is_rand min max]
	ITEM_ATTR_ARY = %w[input_id content has_input]

	def initialize
		@items = []
		@is_rand = false
	end

	def update_issue(issue_obj)
		issue_obj["items"].each do |item_obj|
			item_obj.delete_if { |k, v| !ITEM_ATTR_ARY.include?(k) }
			item_obj["min"] = item_obj["min"].to_i if !item_obj["min"].nil?
			item_obj["max"] = item_obj["max"].to_i if !item_obj["max"].nil?
		end
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
