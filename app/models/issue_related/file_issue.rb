require 'error_enum'
require 'securerandom'
#Besides the fields that all types questions have, file questions also have:
# {
# }
class FileIssue < Issue
  attr_reader :max_number
  attr_writer :max_number

  ATTR_NAME_ARY = %w[max_number]

  def initialize
    @max_number = 1
  end

  def update_issue(issue_obj)
    super(ATTR_NAME_ARY, issue_obj)
  end

  def estimate_answer_time
    return 5
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
