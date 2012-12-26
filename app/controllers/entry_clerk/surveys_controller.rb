#encoding: utf-8

require 'error_enum'
class EntryClerk::SurveysController < EntryClerk::ApplicationController
	
	def csv_header
		survey = Survey.find_by_id params[:survey_id]
		return { :error_code => ErrorEnum::SURVEY_NOT_EXIST, 
						 :error_message => "问卷不存在"} unless survey
		render_json  do 
			survey.csv_header
		end
	end

	def import_answer
		survey = Survey.find_by_id params[:survey_id]
		return { :error_code => ErrorEnum::SURVEY_NOT_EXIST, 
						 :error_message => "问卷不存在"} unless survey
		render_json false do 
			if survey.answer_import(params[:csv])
				success_true 
			else
				{
					:error_code => ErrorEnum::WRONG_ANSWERS,
					:error_message => "答案有误"
				}
			end
		end
	end
end