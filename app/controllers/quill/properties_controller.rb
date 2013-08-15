class Quill::PropertiesController < Quill::QuillController
	
	before_filter :ensure_survey, :only => [:show, :more, :update_more]

	# PAGE: show survey properties
	def show
	end

	# AJAX: update properties
	def update
		render :json => Quill::PropertyClient.new(session_info, params[:questionaire_id]).update_properties(params[:properties])
	end

	# PAGE: more properties
	def more
		@style_setting = @survey['style_setting']
	end

	# AJAX: update more properties
	def update_more
		style_setting = @survey['style_setting'] || {}
		style_setting['has_progress_bar'] = !!params[:has_progress_bar] if params.has_key?(:has_progress_bar)
		style_setting['has_question_number'] = !!params[:has_question_number] if params.has_key?(:has_question_number)
		style_setting['is_one_question_per_page'] = !!params[:is_one_question_per_page] if params.has_key?(:is_one_question_per_page)
		style_setting['has_advertisement'] = !!params[:has_advertisement] if params.has_key?(:has_advertisement)
		style_setting['has_oopsdata_link'] = !!params[:has_oopsdata_link] if params.has_key?(:has_oopsdata_link)
		# style_setting['redirect_link'] = !!params[:redirect_link] if params.has_key?(:redirect_link)
		style_setting['redirect_link'] = params[:redirect_link]
		style_setting['allow_pageup'] = !!params[:allow_pageup] if params.has_key?(:allow_pageup)
		render :json => Quill::StyleClient.new(session_info, params[:questionaire_id]).update_style(style_setting)
	end

end