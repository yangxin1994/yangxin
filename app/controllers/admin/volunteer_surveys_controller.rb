class Admin::VolunteerSurveysController < Admin::AdminController

	layout 'admin_new'

	before_filter :get_client, :except => [:del_question]

	def get_client
		@client = BaseClient.new(session_info, "/admin/surveys")
		# ************
	end

	# *****************************

	def index

		@survey = @client._get({}, "/show_user_attr_survey")
		respond_to do |format|
			format.html
			format.json { render json: @survey}
		end
	end

	def add_template_question
		hash_params ={}
		hash_params = {:question_id => params[:question_id]} if params[:question_id]
		hash_params.merge!({:id => params[:id]}) if params[:id]
		hash_params.merge!({:page_index => params[:page_index]}) if params[:page_index]
		render :json => @client._put(hash_params, "/add_template_question")
	end

	def del_question
		render :json => BaseClient.new(session_info, "/surveys/#{params[:id]}/questions/#{params[:question_id]}")._delete({})
	end

end