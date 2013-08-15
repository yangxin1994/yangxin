class Quill::PreviewsController < Quill::QuillController

	# PAGE: redirect to real preview page
	def show
		# redirect_to p_path(:key => QuillCommon::Encryption.encrypt_preview_key("#{Time.now.to_i}_#{params[:questionaire_id]}"))
		@reward_scheme_id = ::SurveyClient.new(session_info, params[:questionaire_id]).default_reward_scheme_id
		redirect_to show_p_path(@reward_scheme_id.success ? @reward_scheme_id.value : nil)
	end

end