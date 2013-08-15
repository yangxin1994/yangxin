class Quill::SharesController < Quill::QuillController

	before_filter :ensure_survey, :only => [:show]

	def initialize
		super(3)
	end

	# PAGE: show survey share
	def show
		@hide_left_sidebar = true

		@survey_questions = get_survey_questions
		@survey_quota = @survey['quota']

		reward_scheme_id = ::SurveyClient.new(session_info, params[:questionaire_id]).default_reward_scheme_id
		if reward_scheme_id.success
			@short_url = "#{Rails.application.config.quillme_host}#{show_s_path(reward_scheme_id.value)}"
			result = ::ShortUrlClient.new(session_info).create(@short_url)
			if result.success && !result.value.blank?
				@short_url = "#{Rails.application.config.quillme_host}/#{result.value}"
			end
		end
	end

end