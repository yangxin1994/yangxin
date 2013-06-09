# encoding: utf-8
require 'error_enum'
require 'tool'
require 'securerandom'

class HOTSpotIssue < Issue
	
	attr_accessor :visible_type,:min_choice,:max_choice,:image,:items

	ATTR_NAME_ARY = %w[visible_type min_choice max_choice  image items]

	def initialize
      @visible_type = 0 #可选值有0 和1 ，0表示每个region的范围只有在鼠标hover的时候才显示  1表示每个region的范围一直显示  

      @min_choice = 1 #最小选择数，整型(当该题不是必选题的时候，为0，否则为1)

      @max_choice = 1 #最大选择数，整型(当该题无排他项的时候，最大选择数与regons长度相等，否则，为regions长度-1)
      

   
      
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
