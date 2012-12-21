require 'error_enum'
class Interviewer::SurveysController < Interviewer::ApplicationController
	
	def show
		@survey = Survey.find_by_id params[:survey_id]
		render_json_e(ErrorEnum::SURVEY_NOT_EXIST) and return if @survey.nil?
		rnde_json_auto(@survey.info_for_interviewer)
	end
end