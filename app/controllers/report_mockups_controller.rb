class ReportMockupsController < ApplicationController
	before_filter :require_sign_in, :check_normal_survey_existence

	def check_normal_survey_existence
		@survey = (@current_user.is_admin || @current_user.is_super_admin) ? Survey.normal.find_by_id(params[:survey_id]) : @current_user.surveys.normal.find_by_id(params[:survey_id])
		if @survey.nil?
			respond_to do |format|
				format.json	{ render_json_e(ErrorEnum::SURVEY_NOT_EXIST) and return }
			end
		end
	end

	def create
		result = @survey.create_report_mockup(params[:report_mockup])
		respond_to do |format|
			format.json	{ render_json_auto(result) and return }
		end
	end

	def show
		result = @survey.show_report_mockup(params[:id])
		respond_to do |format|
			format.json	{ render_json_auto(result) and return }
		end
	end

	def update
		retval = @survey.update_report_mockup(params[:id], params[:report_mockup])
		respond_to do |format|
			format.json	{ render_json_auto(retval) and return }
		end
	end

	def index
		retval = @survey.list_report_mockups
		respond_to do |format|
			format.json	{ render_json_auto(retval) and return }
		end
	end

	def destroy
		retval = @survey.delete_report_mockup(params[:id])
		respond_to do |format|
			format.json	{ render_json_auto(retval) and return }
		end
	end
end
