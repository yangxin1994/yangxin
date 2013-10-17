require 'error_enum'
require 'securerandom'
#Besides the fields that all types questions have, email blank questions also have:
# {
#   }
class UrlBlankIssue < Issue

  ATTR_NAME_ARY = %w[]

  def initialize
      
  end

  def update_issue(issue_obj)
    super(ATTR_NAME_ARY, issue_obj)
  end

  def estimate_answer_time
    return 2
  end

  def serialize
    super(ATTR_NAME_ARY)
  end
end
