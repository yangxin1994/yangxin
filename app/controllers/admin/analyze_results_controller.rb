class Admin::AnalyzeResultsController < Admin::ApplicationController
	before_filter :check_normal_survey_existence

	def check_normal_survey_existence
		@survey = Survey.normal.find_by_id(params[:survey_id])
		if @survey.nil?
			respond_to do |format|
				format.json	{ render_json_e(ErrorEnum::SURVEY_NOT_EXIST) and return }
			end
		end
	end

	def show
		result = @survey.show_analyze_result(params[:filter_name])
		respond_to do |format|
			format.json	{ render_json_auto(result) and return }
		end

	end
end
