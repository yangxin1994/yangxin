class Quill::AuthoritiesController < Quill::QuillController
	
	before_filter :ensure_survey, :only => [:show]

	# PAGE: show survey authority
	def show
		@authority = @survey['access_control_setting']
	end

	# AJAX: update survey authority
	def update
		render :json => Quill::AuthorityClient.new(session_info, params[:questionaire_id]).update(params[:authority])
	end
	
end