require 'error_enum'
require 'securerandom'
#Besides the fields that all types questions have, address blank questions also have:
# {
#  "has_postcode" : whether has a postcode input(Boolean)
#  "format" : format of the input, an integer in the interval of [1, 15]. If converted into a binary number, it has 4 digits, indicating whether this has "province", "city", "county", "detailed address"(Integer)
# }
class AddressBlankIssue < Issue
  
  attr_reader :has_postcode, :format
  attr_writer :has_postcode, :format

  ATTR_NAME_ARY = %w[has_postcode format]

  def initialize
    @has_postcode = true
    @format = 15
  end

  def update_issue(issue_obj)
    issue_obj["format"] = issue_obj["format"].to_i
    issue_obj["has_postcode"] = issue_obj["has_postcode"].to_s == "true"
    super(ATTR_NAME_ARY, issue_obj)
  end

  def estimate_answer_time
    answer_time = 0
    answer_time = answer_time + 1 if (format & 8) != 0
    answer_time = answer_time + 1 if (format & 4) != 0
    answer_time = answer_time + 1 if (format & 2) != 0
    answer_time = answer_time + 1 if (format & 1) != 0
    answer_time = answer_time + 1 if has_postcode
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
