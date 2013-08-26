class Admin::TemplateQuestionsController < Admin::AdminController

	layout 'admin_new'

	before_filter :get_client

	def get_client
		@client = BaseClient.new(session_info, "/admin/template_questions")
	end

	# *****************************

	def get_text
		render :json => @client._get({}, "/#{params[:id]}/get_text") and return
	end
	
	def index
		parameters={:page => page,:per_page => per_page}
		parameters.merge!({question_type: params[:question_type].to_i}) unless params[:question_type].nil?
		@template_questions = @client._get(parameters, "")

		respond_to do |format|
			format.html
			format.json { render json: @template_questions}
		end
	end

	def show
		@template_question = @client._get({}, "/#{params[:id]}")
		
		respond_to do |format|
			format.html
			format.json { render json: @template_question}
		end
	end

	def create
		@result = @client._post(
			{
				:question_type => params[:question_type],
			})
		render_result
	end

	def update
		#construct 
		_question = {
						content: {text: params[:content], audio: "", image: "", video: ""}, 
						note: "",
						attribute_name: params[:attribute_name],
					 	issue: params[:issue]
					}
		#add items		
		_question[:issue][:items] = _question[:issue][:items].values if params[:issue] && params[:issue].has_key?(:items)
		_question[:issue][:rows] = _question[:issue][:rows].values if params[:issue] && params[:issue].has_key?(:rows)
		# _question[:issue][:labels] = _question[:issue][:labels].values if params[:issue] && params[:issue].has_key?(:labels)
		@result = @client._put({
				:question => _question
			}, "/#{params[:id]}")
		render_result
	end

	def destroy
		@result = @client._delete({}, "/#{params[:id]}")
		render_result
	end

end