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
		if params[:question_ids]
			@survey = Survey.find_by_id(params[:id]) if params[:id]
			unless @survey
				@survey = Survey.create
				@survey.alt_new_survey = false
				@current_user.surveys << @survey
				@survey.set_user_attr_survey(true)
			end
			params[:question_ids].each do |id|
				@survey.insert_template_question( params[:page_index].to_s.to_i, 
					"-1", id)	
			end

			render_json_auto true
		else
			render_json_auto false
		end
	end

	def allocate
		@survey = Survey.normal.find_by_id(params[:id])
		render_json_auto(ErrorEnum::SURVEY_NOT_EXIST) and return if @survey.nil?
		retval = @survey.allocate(params[:system_user_type], params[:user_id], params[:allocate].to_s == "true")
		render_json_auto(retval) and return
	end

	def add_reward
		@survey = Survey.find_by_id(params[:id])
		params[:lottery] = lottery.find_by_id(params[:lottery_id])
		s = params[:survey].select{:reward || :point || :lottery}
		respond_and_render_json @survey.update_attributes(s)
	end	

	def set_community
		@survey = Survey.normal.find_by_id(params[:id])
		render_json_auto(ErrorEnum::SURVEY_NOT_EXIST) and return if @survey.nil?
		retval = @survey.set_community(params[:show_in_community].to_s == "true")
		render_json_auto(retval) and return
	end
end