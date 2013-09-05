class Admin::FeedbacksController < Admin::AdminController

	layout 'admin_new'
	before_filter :get_client

	def get_client
		@client = BaseClient.new(session_info, "/admin/feedbacks")
	end

	# ****************************
	
	def index
		hash_params={:page=> page, :per_page => per_page}
		hash_params.merge!({:answer=> params[:is_answer].to_s == "true"}) if params[:is_answer]
		hash_params.merge!({:title => params[:title]}) if params[:title]
		@feedbacks = @client._get(hash_params)

		respond_to do |format|
			format.html
			format.json { render json: @feedbacks}
		end
	end

	def show
		@feedback = @client._get({},"/#{params[:id]}")
		respond_to do |format|
			format.html
			format.json { render json: @feedback}
		end
	end

	# def create
		
	# end

	# def update
		
	# end

	def destroy
		@result = @client._delete({},"/#{params[:id]}")
		render :json => @result
	end

	def reply
		@result = @client._post({:message_content => params[:message_content]}, "/#{params[:id]}/reply")
		logger.debug "repley::::: #{JSON.parse(@result.to_json)}"
		render :json => @result
	end

end