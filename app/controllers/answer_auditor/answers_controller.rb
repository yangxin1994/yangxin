require 'error_enum'
class AnswerAuditor::AnswersController < AnswerAuditor::ApplicationController
	
	def index
		survey = @current_user.answer_auditor_allocated_surveys.find_by_id(params[:survey_id])
		render_json_e(ErrorEnum::SURVEY_NOT_EXIST) and return if survey.nil?
		render_json_auto(survey.answers.unreviewed)
	end

	def show
		answer = Answer.find_by_id(params[:id])
		render_json_e(ErrorEnum::ANSWER_NOT_EXIST) and return if answer.nil?
		render_json_auto(answer)
	end

	def review
		answer = Answer.find_by_id(params[:id])
		render_json_e(ErrorEnum::ANSWER_NOT_EXIST) and return if answer.nil?
		retval = answer.review(params[:review_result], @current_user)
		render_json_auto(retval)
	end
end