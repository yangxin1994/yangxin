class Travel::InterviewersController < Travel::TravelController
	def show
		@survey = Survey.find(params[:survey_id])
		@task   = InterviewerTask.find(params[:id])
		#@answers = @survey.answers.where(interviewer_task_id:@task.id.to_s)
 		@answers = Answer.desc()
		if params[:suffice] == 'true'
			@answers = @answers.where(status:Answer::FINISH)
		end

		@answers = auto_paginate(@answers) do |paged_answer|
			paged_answer.map{|answer| answer.travel_info}
		end

		if request.xhr?
			render_json_auto(@answers)
		end

	end
end