class SurveyAuditor::ApplicationController < ApplicationController
	before_filter :require_survey_auditor

	def check_normal_survey_existence
		@survey = Survey.normal.find_by_id(params[:id])
		if @survey.nil?
			respond_to do |format|
				format.json	{ render :json => ErrorEnum::SURVEY_NOT_EXIST and return }
			end
		end
	end
end
