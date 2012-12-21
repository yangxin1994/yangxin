require 'error_enum'
class EntryClerk::SurveysController < EntryClerk::ApplicationController
	
	def csv_header
		survey = Survey.find_by_id params[:survey_id]
		render_json(!!survey) do |is_success|
			if is_success
				survey.csv_header
			else
				ErrorEnum::SURVEY_NOT_EXIST
			end
		end
	end

	def import_answer
		survey = Survey.find_by_id params[:survey_id]
		render_json(survey.valid?) do
			if is_success
				survey.answer_import(params[:csv])
			else
				survey.as_retval
			end
		end
	end
end