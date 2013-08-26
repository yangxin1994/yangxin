class Quill::CustomizationsController < Quill::QuillController

	before_filter :ensure_survey

	def initialize
		super(2)
	end

	# PAGE: show survey customizations
	def show
		@hide_left_sidebar = true
		@stylesheet = @survey.style_setting['style_sheet_name'] if @survey.style_setting
	end

	# AJAX: update stylesheet
	def update
		style_setting = @survey.style_setting || {}
		retval = @survey.update_style_setting(style_setting)
		render_json_auto retval
	end
end