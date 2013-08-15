class Quill::LogicsController < Quill::QuillController
	
	before_filter :ensure_survey, :only => [:show, :index]

	before_filter :get_ws_client, :only => [:destroy, :update, :create]
	
	def get_ws_client
		@ws_client = Quill::LogicClient.new(session_info, params[:questionaire_id])
	end

	# PAGE: index survey logics
	def index
		@survey_questions = get_survey_questions
	end

	# PAGE: show survey logic
	def show
		@survey_questions = get_survey_questions
		logics = @survey['logic_control'] || []
		@current_index = -1
		@current_logic = nil
		index = params[:id].to_s
		if index.to_i.to_s == index
			index = index.to_i
			if index >= 0 && index < logics.length
				@current_index = index
				@current_logic = logics[index]
			end
		end
	end

	# AJAX: destory a logic by its index
	def destroy
		render :json => @ws_client.remove(params[:id].to_i)
	end

	# AJAX: update s logic by its index
	def update
		render :json => @ws_client.update(params[:id].to_i, params[:logic])
	end

	# AJAX: create a new logic
	def create
		render :json => @ws_client.create(params[:logic])
	end

end