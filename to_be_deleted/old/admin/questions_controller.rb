class Admin::QuestionsController < Admin::ApplicationController

	before_filter :check_question_existence


	def check_question_existence
		@question = Question.find_by_id(params[:id])
		render_json_auto(ErrorEnum::QUESTION_NOT_EXIST) and return unless @question
	end

	def show
		render_json_auto @question and return
	end

	def remove_sample_attribute
		render_json_auto @question.remove_sample_attribute and return
	end

end