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


	# summarize the results
	# the data needed includes:
	#  1. published time and the time duration published
	#  2. the number of answers received, including
	#    (1). the aggregate number
	#    (2). the numbers for each filter
	#    (3). the numbers for each quota
	#    (4). the numbers that are rejected due to quota, screen, quality control
	def index
		publish_status = @survey.publish_status
		publish_time = @survey.get_last_publish_time
		
	end
end
