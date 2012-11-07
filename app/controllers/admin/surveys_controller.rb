class Admin::SurveysController < Admin::ApplicationController

	def index
		@surveys = Survey.all.page(page).per(per_page)
		render_json_auto(@surveys)
	end

	def count
		render_json_auto Survey.count
	end

	def list_by_status
		@surveys = Survey.all.page(page).per(per_page)
		render_json_auto(@surveys)
	end

	def list_by_status_count
		@surveys = Survey.all.page(page).per(per_page)
		render_json_auto(@surveys)
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
end