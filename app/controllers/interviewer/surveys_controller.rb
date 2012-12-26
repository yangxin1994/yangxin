require 'error_enum'
require 'quill_common'
class Interviewer::SurveysController < Interviewer::ApplicationController
	
	def show
		@survey = Survey.find_by_id params[:survey_id]
		render_json_e(ErrorEnum::SURVEY_NOT_EXIST) and return if @survey.nil?
		render_json_e(ErrorEnum::SURVEY_NOT_PUBLISHED) and return if @survey.publish_status != QuillCommon::PublishStatusEnum::PUBLISHED
		rnde_json_auto(@survey.info_for_interviewer)
	end
end