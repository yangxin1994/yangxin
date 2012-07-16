require 'error_enum'
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

	attr_reader :items, :is_rand, :sum
	attr_writer :items, :is_rand, :sum

	ATTR_NAME_ARY = %w[items is_rand sum]
	ITEM_ATTR_ARY = %w[content has_input]

	def initialize
		@items = []
		@is_rand = false
		@sum = 100
	end

	def update_issue
		issue_obj["items"].each do |item_obj|
			item_obj.delete_if { |k, v| !ITEM_ATTR_ARY.include?(k) }
		end
		issue_obj["sum"] = issue_obj["sum"].to_i
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
