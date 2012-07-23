# encoding: utf-8
require 'error_enum'
require 'securerandom'
#Besides the fields that all types questions have, number blank questions also have:
# {
#	 "input_id" : id of the number input
#	 "precision" : number decimals
#	 "min_value" : minimal value of the number(Float)
#	 "max_value" : maximal value of the number(Float)
#	 "unit" : unit
#	}
class NumberBlankIssue < Issue

	attr_reader :precision, :min_value, :max_value, :unit
	attr_writer :precision, :min_value, :max_value, :unit

	ATTR_NAME_ARY = %w[precision min_value max_value unit]

	def initialize
		@precision = 0
		@min_value = 0
		@max_value = 100
		@unit = ""
	end


	def update_issue(issue_obj)
		issue_obj["precision"] = issue_obj["precision"].to_i
		issue_obj["min_value"] = issue_obj["min_value"].to_i
		issue_obj["max_value"] = issue_obj["max_value"].to_i
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
