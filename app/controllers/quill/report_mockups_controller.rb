# finish migrating
class Quill::ReportMockupsController < Quill::QuillController

	before_filter :ensure_survey

	def initialize
		super(4)
	end

	# PAGE: index survey report mockups
	def index
		@report_mockups = @survey.list_report_mockups
	end

	# AJAX: create a new mockup
	def create
		retval = @survey.create_report_mockup(params[:report_mockup])
		render_json_auto retval and return
	end

	# AJAX
	def destroy
		retval = @survey.delete_report_mockup(params[:id])
		render_json_auto retval and return
	end

	# PAGE: show report mockuup
	def show
		result = @survey.show_report_mockup(params[:id])
		# result = @ws_client.show(params[:id])
		if result.present?
			@report_mockup = result
			@survey_questions = get_survey_questions
		else
			respond_to do |format|
				format.html { redirect_to questionaire_report_mockups_path and return }
				format.json { render_json_e ErrorEnum::REPORT_MOCKUP_NOT_EXIST }
				# format.json { return_json result }
			end
		end
	end

	# AJAX
	def update
		retval = @survey.update_report_mockup(params[:id], params[:report_mockup])
		render_json_auto retval and return
	end
end