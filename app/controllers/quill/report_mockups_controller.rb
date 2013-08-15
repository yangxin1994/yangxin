class Quill::ReportMockupsController < Quill::QuillController

	before_filter :ensure_survey, :only => [:show, :index]

	before_filter :get_ws_client
	
	def get_ws_client
		@ws_client = Quill::ReportMockupClient.new(session_info, params[:questionaire_id])
	end

	def initialize
		super(4)
	end

	# PAGE: index survey report mockups
	def index
		result = @ws_client.index
		if result.success
			@report_mockups = result.value
		else
			respond_to do |format|
				format.html { redirect_to root_path and return }
				format.json { return_json result }
			end
		end
	end

	# AJAX: create a new mockup
	def create
		render :json => @ws_client.create(params[:report_mockup])
	end

	# AJAX
	def destroy
		render :json => @ws_client.destroy(params[:id])
	end

	# PAGE: show report mockuup
	def show
		result = @ws_client.show(params[:id])
		if result.success
			@report_mockup = result.value
			@survey_questions = get_survey_questions
		else
			respond_to do |format|
				format.html { redirect_to questionaire_report_mockups_path and return }
				format.json { return_json result }
			end
		end
	end

	# AJAX
	def update
		render :json => @ws_client.update(params[:id], params[:report_mockup])
	end

end