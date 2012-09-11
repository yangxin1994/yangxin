class ResultsController < ApplicationController
	before_filter :require_sign_in, :check_survey_existence

	def check_survey_existence
		@survey = @current_user.surveys.find_by_id(params[:survey_id])
		if @survey.nil?
			respond_to do |format|
				format.json	{ render_json_e(ErrorEnum::SURVEY_NOT_EXIST) and return }
			end
		end
	end
end
