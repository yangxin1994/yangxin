class Quill::QuillController < ApplicationController
	
	before_filter :require_sign_in

	def initialize(step = 1)
		@current_step = step
		super()
	end

	def ensure_survey
		return @survey if @survey

		@survey_client = Quill::SurveyClient.new(session_info)
		result = @survey_client.get_survey(params[:questionaire_id])

		if !result.success || ( !is_admin && result.value['user_id'] != user_id )
			# if get survey failed or has no right to edit survey
			respond_to do |format|
				format.html { redirect_to questionaires_path and return }
				format.json { return_json result }
			end
		else
			@survey = result.value
		end
	end

	def get_survey_questions
		ensure_survey
		survey_questions = { :pages => [] }
		page_client = Quill::PageClient.new(session_info, @survey['_id'])
		(@survey['pages'] || []).each_with_index do |page, i|
			result = page_client.get_page_questions(i)
			if result.success
				survey_questions[:pages] << result.value
			end
		end
		return survey_questions
	end
	
end