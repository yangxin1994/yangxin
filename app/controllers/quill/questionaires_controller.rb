class Quill::QuestionairesController < Quill::QuillController

	before_filter :get_ws_client, :except => [:show]

	before_filter :ensure_survey, :only => [:show]

	def get_ws_client
		@ws_client = Quill::SurveyClient.new(session_info)
	end
	
	# PAGE: list survey
	# GET
	def index
		# add stars survey in Index action
		@stars = params[:stars].to_b
		@status = params[:status]
		if !params[:title].nil?
			@surveys =@ws_client.search_title(params[:title], page, per_page)
		elsif params[:stars].nil? then
			@surveys = @ws_client.survey_list(params[:status], page, per_page) || []
		else
			@surveys = @ws_client.stars(page, per_page) || []
		end	

		respond_to do |format|
			format.html {
				# Avoid: session is not time out but authkey time out. 
				# Quill Web thinks that the user is signed in so the before_filter of require_sign_in return true, 
				# however, web serivce returns require_login_in error
				# TODO: to be more elegance
				_sign_out and return if @surveys.require_login?
			}# index.html.erb
			format.json { render json: @surveys}
		end
	end

	# PAGE
	def new
		result = @ws_client.new_survey
		redirect_to result.success ? questionaire_path(result.value['_id']) : questionaires_path
	end

	# AJAX: clone survey
	def clone
		render :json => @ws_client.clone(params[:id], params[:title])
	end

	# PAGE: show and edit survey
	def show
		@locked = (!is_admin && @survey['publish_status'] == 8) 
	end

	# AJAX: delete survey
	def destroy
		render :json => @ws_client.delete(params[:questionaire_id])
	end

	# PUT
	def recover
		render :json => @ws_client.recover(params[:id])
	end

	#GET
	def remove
		result = @ws_client.clear(params[:id])
		# sign_out and return if result.require_login?
		render :json => result
	end

	# get
	def update_star
		result = @ws_client.update_star(params[:id], params[:is_star])
		# sign_out and return if result.require_login?
		render :json => result
	end

	# AJAX: publish survey
	def publish
		render :json => @ws_client.publish(params[:id])
	end
	
	# AJAX: set deadline
	def deadline
		render :json => @ws_client.set_deadline(params[:id], params[:deadline].to_i)
	end

	# AJAX: close a published survey
	def close
		render :json => @ws_client.close(params[:id])
	end

end
