require 'error_enum'
class Interviewer::AnswersController < Interviewer::ApplicationController
	
	def submit
		interviewer_task = InterviewerTask.find_by_id(params[:interviewer_task_id])
		render_json_auto(ErrorEnum::INTERVIEWER_TASK_NOT_EXIST) and return if interviewer_task.nil?
		retval = interviewer_task.submit_answers(params[:answers])
		render_json_auto(retval) and return
	end
end
