require 'error_enum'
require 'securerandom'
#Besides the fields that all types questions have, time blank questions also have:
# {
#	 "format" : format of the input, an integer in the interval of [1, 127]. If converted into a binary number, it has 7 digits, indicating whether this has "year", "month", "week", "day", "hour", "minutu", "second", from the most significant digit(Integer)
#	}
class TimeBlankIssue < Issue

	attr_reader :format, :min_time, :max_time
	attr_writer :format, :min_time, :max_time

	ATTR_NAME_ARY = %w[format min_time max_time]

	def initialize
		@format = 127
		@min_time = Array.new(7) { |i| -1 }
		@max_time = Array.new(7) { |i| -1 }
	end

	def update_issue(issue_obj)
		issue_obj["format"] = issue_obj["format"].to_i
		issue_obj["min_time"].map! { |e| e.to_i }
		issue_obj["max_time"].map! { |e| e.to_i }
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
