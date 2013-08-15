class Quill::QualitiesController < Quill::QuillController
	
	before_filter :ensure_survey

	# PAGE: show survey quality
	def show
		@quality_questions = nil
		result = Quill::QualityClient.new(session_info).index(3)
		@quality_questions = result.value if result.success

		logger.debug @survey.inspect
		@quality_control_questions_type = @survey['quality_control_questions_type']
		@quality_control_questions_type = 0 if @quality_control_questions_type.blank?
		logger.debug @quality_control_questions_type
		@quality_control_questions_ids = @survey['quality_control_questions_ids']
		logger.debug @quality_control_questions_ids
	end

	# AJAX: update survey quality
	def update
		render :json => Quill::QualityClient.new(session_info).update(
			params[:questionaire_id], params[:quality_control_questions_type], params[:quality_control_questions_ids])
	end
	
end