class AnswerAuditor::AnswersController < ApplicationController
	before_filter :require_answer_auditor

	def index
		render_json_auto Answer.where(finish_type: 0).page(page).per(per_page)
	end

	def count
		render_json_auto Answer.where(finish_type: 0).count
	end

	def show
		answer = Answer.find_by_id(params[:id])
		render_json_auto Error::ANSWER_NOT_EXIST unless answer
		render_json_auto answer
	end

	def update
		answer = Answer.find_by_id(params[:id])
		render_json_auto Error::ANSWER_NOT_EXIST unless answer 
		answer.update_attributes({finish_type: params[:finish_type].to_i})
		render_json_auto answer.save
	end

	def destroy
		answer = Answer.find_by_id(params[:id])
		render_json_auto Error::ANSWER_NOT_EXIST unless answer 
		render_json_auto answer.destroy
	end

end