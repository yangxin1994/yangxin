class Travel::AnswersController < Travel::TravelController
	def show
    	@questions = Answer.find(params[:id]).present_auditor
    	@survey = @questions.survey		
	end
end