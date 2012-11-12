class SurveyAuditor::ApplicationController < ApplicationController
	before_filter :require_answer_auditor

	def check_normal_survey_existence
		@survey = Survey.normal.find_by_id(params[:id])
		if @survey.nil?
			respond_to do |format|
				format.json	{ render_json_e(ErrorEnum::SURVEY_NOT_EXIST) and return }
			end
		end
	end
end
