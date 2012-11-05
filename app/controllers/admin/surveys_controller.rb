class Admin::SurveysController < Admin::ApplicationController

	def list_by_status
		@surveys = Survey.where(status: params[:status].to_i).page(page).per(per_page)
		render_json_auto(@surveys)
	end

	def list_by_status_count
		@surveys = Survey.where(status: params[:status].to_i).page(page).per(per_page)
		render_json_auto(@surveys)
	end

	def show_user_attr_survey
		@survey = Survey.get_user_attr_survey
		render_json_auto @survey
	end

	def add_questions
		@survey = Survey.find_by_id(params[:id]) if params[:id]
		unless @survey
			@survey = Survey.create
			@survey.set_user_attr_survey(true)
		end
		if params[:question_ids]
			params[:question_ids].each do |id|
				@survey.insert_template_question( params[:page_index].to_s.to_i, 
					"-1", id)	
			end
			render_json_auto true
		else
			render_json_auto false
		end
		
	end

end