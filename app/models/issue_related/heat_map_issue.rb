# encoding: utf-8
require 'error_enum'
require 'tool'
require 'securerandom'

class HeatMapIssue < Issue
    
    attr_accessor :max_click_num,:min_click_mum,:image,:items

    ATTR_NAME_ARY = %w[max_click_num min_click_mum image items]

    def initialize
      @min_click_mum = 1
      @min_click_mum = 10               
    end

    def update_issue(issue_obj)
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
