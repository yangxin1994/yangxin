class Quill::FiltersController < Quill::QuillController
	
	before_filter :ensure_survey, :only => [:show, :index]

	before_filter :get_ws_client, :only => [:destroy, :update, :create]

	def initialize
		super(4)
	end
	
	def get_ws_client
		@ws_client = Quill::FilterClient.new(session_info, params[:questionaire_id])
	end

	# PAGE: index survey filters
	def index
		@survey_questions = get_survey_questions
	end

	# PAGE: show survey filter
	def show
		@survey_questions = get_survey_questions

		filters = @survey['filters'] || []
		@current_index = -1
		@current_filter = nil
		index = params[:id].to_s
		if index.to_i.to_s == index
			index = index.to_i
			if index >= 0 && index < filters.length
				@current_index = index
				@current_filter = filters[index]
			end
		end
	end

	# AJAX: destory a filter by its index
	def destroy
		render :json => @ws_client.remove(params[:id].to_i)
	end

	# AJAX: update filter by its index
	def update
		render :json => @ws_client.update(params[:id].to_i, params[:filter])
	end

	# AJAX: create a new filter
	def create
		render :json => @ws_client.create(params[:filter])
	end

end