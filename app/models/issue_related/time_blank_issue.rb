require 'error_enum'
require 'securerandom'
#Besides the fields that all types questions have, time blank questions also have:
# {
#    "format" : format of the input, an integer in the interval of [0, 6]
#   }
class TimeBlankIssue < Issue

  attr_reader :format, :min, :max
  attr_writer :format, :min, :max

  ATTR_NAME_ARY = %w[format min max]

  def initialize
    @format = 2
    @min = nil
    @max = nil
  end

  def update_issue(issue_obj)
    issue_obj["format"] = issue_obj["format"].to_i
    issue_obj["min"] = issue_obj["min"].to_i
    issue_obj["max"] = issue_obj["max"].to_i
    super(ATTR_NAME_ARY, issue_obj)
  end

  def estimate_answer_time
    return 2
  end

  def serialize
    super(ATTR_NAME_ARY)
  end
end
