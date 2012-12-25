require 'error_enum'
class Interviewer::InterviewerTasksController < Interviewer::ApplicationController
	
	def index
		interviewer_tasks = @current_user.interviewer_tasks
		render_json_auto interviewer_tasks
	end
end