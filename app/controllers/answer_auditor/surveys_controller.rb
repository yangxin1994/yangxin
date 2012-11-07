# encoding: utf-8
require 'error_enum'
class AnswerAuditor::SurveysController < AnswerAuditor::ApplicationController

	def index
		# first parameter is survey status (0 for normal surveys)
		# second parameter is survey publish status (2 for under review surveys)
		# third parameter are tags
		survey_list = @current_user.answer_auditor_allocated_surveys
		respond_to do |format|
			format.json	{ render_json_auto(survey_list.serialize) and return }
		end
	end
end
