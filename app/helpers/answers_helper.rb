# encoding: utf-8

module AnswersHelper

	def answer_type_tag(status)
		tag = ""
		case status.to_i

		when 2
			tag = '已拒绝'
		when 4
			tag = '待审核'
		when 
			tag = '待代理审核'

		when 32
			tag = '通过审核'

		end
		tag.html_safe
	end

end
