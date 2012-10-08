require 'error_enum'
require 'securerandom'
#Besides the fields that all types questions have, text blank questions also have:
# {
#	 "min_length" : minimal length of the input text(Integer)
#	 "max_length" : maximal length of the input text(Integer)
#	 "has_multiple_line" : whether has multiple lines to input(Boolean)
#	 "size" : size of the input, can be 0(small), 1(middle), 2(big)
#	}
class TextBlankIssue < Issue

	attr_reader :min_length, :max_length, :has_multiple_line, :size
	attr_writer :min_length, :max_length, :has_multiple_line, :size

	ATTR_NAME_ARY = %w[min_length max_length has_multiple_line size]

	def initialize
		@min_length = 1
		@max_length = 10
		@has_multiple_line = false
		@size = 0
	end


	def update_issue(issue_obj)
		issue_obj["min_length"] = issue_obj["min_length"].to_i
		issue_obj["max_length"] = issue_obj["max_length"].to_i
		issue_obj["size"] = issue_obj["size"].to_i
		issue_obj["has_multiple_line"] = (issue_obj["has_multiple_line"].to_s == "true")
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
