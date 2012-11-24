# encoding: utf-8
require 'error_enum'
class AnswerAuditor::SurveysController < AnswerAuditor::ApplicationController

	def index
		if @current_user.is_admin
			render_json_auto auto_paginate(Survey.where(
					user_attr_survey: false, 
					:new_survey => false, 
					:publish_status.gt => 2
				))
		else
			render_json_auto auto_paginate(@current_user.answer_auditor_allocated_surveys)
		end
	end
end
