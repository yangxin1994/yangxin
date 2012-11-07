require 'error_enum'
class EntryClerk::AnswersController < EntryClerk::ApplicationController
	
	def csv_header
		survey = Survey.find_by_id params[:survey_id]
		respond_and_render_json(survey.is_valid?) do
			if is_success
				survey.get_csv_header
			else
				survey.as_retval
			end
		end
	end

	def import_answer
		survey = Survey.find_by_id params[:survey_id]
		respond_and_render_json(survey.is_valid?) do
			if is_success
				survey.answer_import(params[:csv])
			else
				survey.as_retval
			end
		end
	end
end
