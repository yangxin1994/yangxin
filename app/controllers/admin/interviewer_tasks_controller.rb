class Admin::InterviewerTasksController < Admin::ApplicationController


	def index
		@survey = Survey.find_by_id(params[:survey_id])
		render_json_e(ErrorEnum::SURVEY_NOT_EXIST) and return if @survey.nil?

		interviewer_tasks = @survey.interviewer_tasks
		render_json_auto(interviewer_tasks)	and return
	end

	def show
		@interviewer_task = InterviewerTask.find_by_id(params[:id])
		render_json_auto(ErrorEnum::INTERVIEWER_TASK_NOT_EXIST) and return unless @interviewer_task
		render_json_auto @interviewer_task
	end

	def create
		interviewer_task_inst = InterviewerTask.create_interviewer_task(params[:survey_id],
																		params[:user_id],
																		params[:quota])
		render_json_auto interviewer_task_inst
	end

	def update
		@interviewer_task = InterviewerTask.find_by_id(params[:id])
		render_json_auto(ErrorEnum::INTERVIEWER_TASK_NOT_EXIST) and return unless @interviewer_task
		retval = @interviewer_task.update_quota(params[:quota])
		render_json_auto retval
	end
end