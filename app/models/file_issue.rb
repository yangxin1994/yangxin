require 'error_enum'
require 'securerandom'
#Besides the fields that all types questions have, file questions also have:
# {
#	 "input_id" : id of the input
#	}
class FileIssue < Issue

	ATTR_NAME_ARY = []

	def initialize
	end

	def update_issue(issue_obj)
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
