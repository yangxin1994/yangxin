class Admin::QuestionsController < Admin::ApplicationController

	def show
		@question = Question.find_by_id(params[:id])
		render_json_auto(ErrorEnum::QUESTION_NOT_EXIST) and return unless @question
		render_json_auto @question and return
	end

end