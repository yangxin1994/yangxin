require 'error_enum'
class Interviewer::InterviewerTasksController < Interviewer::ApplicationController
	
	def index
		interviewer_tasks = @current_user.interviewer_tasks
		render_json_auto interviewer_tasks
	end

	def show
		interviewer_task = @current_user.interviewer_tasks.find_by_id(params[:interviewer_task_id])
		render_json_auto ErrorEnum::INTERVIEWER_TASK_NOT_EXIST and return if interviewer_task.nil?
		render_json_auto interviewer_task
	end
end