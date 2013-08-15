class Quill::CustomizationsController < Quill::QuillController

	before_filter :ensure_survey

	def initialize
		super(2)
	end

	# PAGE: show survey customizations
	def show
		@hide_left_sidebar = true
		@stylesheet = @survey['style_setting']['style_sheet_name'] if @survey['style_setting']
	end

	# AJAX: update stylesheet
	def update
		style_setting = @survey['style_setting'] || {}
		style_setting['style_sheet_name'] = params[:stylesheet]
		render :json => Quill::StyleClient.new(session_info, params[:questionaire_id]).update_style(style_setting)
	end
	
end