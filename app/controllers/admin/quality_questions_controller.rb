class Admin::QualityQuestionsController < Admin::AdminController
	layout 'admin_new'
	
	before_filter :get_client

	def get_client
		@client = BaseClient.new(session_info, "/admin/quality_control_questions")
	end

	# *****************************
	
	def objective
		@quality_questions = @client._get({:page => page,:per_page => per_page}, "/objective_questions")
		_sign_out and return if @quality_questions.require_admin?
		respond_to do |format|
			format.html
			format.json { render json: @quality_questions}
		end
	end

	def matching
		@quality_questions = @client._get({:page => page,:per_page => per_page}, "/matching_questions")
		_sign_out and return if @quality_questions.require_admin?
		respond_to do |format|
			format.html
			format.json { render json: @quality_questions}
		end
	end

	def show
		@quality_question = @client._get({}, "/#{params[:id]}")
		_sign_out and return if @quality_question.require_admin?
		@question_objects = @quality_question.value[0, @quality_question.value.length-1]
		@quality_control_question_answer = @quality_question.value[@quality_question.value.length-1]
		respond_to do |format|
			format.html
			format.json { render json: @quality_question}
		end
	end

	def create
		@result = @client._post(
			{
				:quality_control_type => params[:quality_control_type],
				:question_type => params[:question_type],
				:question_number => params[:question_number]
			})
		render_result
	end

	def update
		#construct 
		_question = {
						content: {text: params[:content], audio: "", image: "", video: ""}, 
						note: "",
					 	issue: {
					 		max_choice: params[:max_choice].to_i,
					 		min_choice: params[:min_choice].to_i,
					 		items: [],
					 		option_type: (params[:min_choice].to_i == 1 && params[:max_choice].to_i == 1) ? 0 : 6
					 	}
					}
		#add items
		params[:items].each do |k,v|
			_question[:issue][:items] << v
		end
		@result = @client._put({
				:question => _question
			}, "/#{params[:id]}")
		render_result
	end

	def update_answer
		#reconstruct params[:answer_content], because of matching_items's item contains js object,not normal string.
		if params[:answer_content][:matching_items] then
			matching_items = params[:answer_content][:matching_items];
			params[:answer_content][:matching_items] = []
			matching_items.each do |k,v|
				params[:answer_content][:matching_items] << v
			end
		end
		@result = @client._put({
				:quality_control_type => params[:quality_control_type],
				:answer => params[:answer_content]
			}, "/#{params[:id]}/update_answer")
		render_result
	end

	def destroy
		@result = @client._delete({}, "/#{params[:id]}")
		render_result
	end

end