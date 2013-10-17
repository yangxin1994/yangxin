require 'error_enum'
require 'securerandom'
#Besides the fields that all types questions have, phone blank questions also have:
# {
#    "phone_type" : 1 for fixed phone number, 2 for mobile number, 3 for both fixed phone number and mobile number
#   }
class PhoneBlankIssue < Issue
    
  attr_reader :phone_type
  attr_writer :phone_type

  ATTR_NAME_ARY = %w[phone_type]

  def initialize
    @phone_type = 1     
  end

  def update_issue(issue_obj)
    issue_obj["phone_type"] = issue_obj["phone_type"].to_i
    super(ATTR_NAME_ARY, issue_obj)
  end

  def estimate_answer_time
    answer_time = 0
    answer_time = answer_time + 1 if (phone_type & 2) != 0
    answer_time = answer_time + 1 if (phone_type & 1) != 0
    return answer_time
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
