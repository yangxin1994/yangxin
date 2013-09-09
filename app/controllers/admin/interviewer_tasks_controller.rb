class Admin::InterviewerTasksController < Admin::AdminController
	layout 'admin_new'

	before_filter :get_client

	def get_client
		@client = BaseClient.new(session_info, "/admin/interviewer_tasks")
	end
	# *******************************

	def index
		@interviewer_tasks = @client._get({:survey_id => params[:publish_id]})
		respond_to do |format|
			format.html
			format.json { render json: @interviewer_tasks}
		end
	end

	def show
		@interviewer_task = @client._get({}, "/#{params[:id]}")
		respond_to do |format|
			format.html
			format.json { render json: @interviewer_task}
		end
	end

	def create
		hash_params = {
			:survey_id => params[:publish_id],
			:user_id => params[:user_id],
			:quota => params[:quota]
		}
		if hash_params[:quota] && hash_params[:quota].has_key?(:rules) &&
			 hash_params[:quota][:rules] && hash_params[:quota][:rules].is_a?(Hash)

			_rules = hash_params[:quota][:rules].values 
			_rules.each do |_rule|
				if _rule.has_key?(:conditions) && _rule[:conditions].is_a?(Hash)
					_rule = _rule[:conditions].values
				end
			end

			hash_params[:quota][:rules] = _rules
		end
		
		@interviewer_task = @client._post(hash_params)
		# respond_to do |format|
		# 	format.html
		# 	format.json { render json: @interviewer_task}
		# end
		render :json => @interviewer_task
	end

	def update
		hash_params = {
			:quota => params[:quota]
		}
		if hash_params[:quota] && hash_params[:quota].has_key?(:rules) &&
			 hash_params[:quota][:rules] && hash_params[:quota][:rules].is_a?(Hash)

			_rules = hash_params[:quota][:rules].values 
			_rules.each do |_rule|
				if _rule.has_key?(:conditions) && _rule[:conditions].is_a?(Hash)
					_rule = _rule[:conditions].values
				end
			end

			hash_params[:quota][:rules] = _rules
		end
		@interviewer_task = @client._put(hash_params, "/#{params[:id]}")
		# respond_to do |format|
		# 	format.html
		# 	format.json { render json: @interviewer_task}
		# end

		render :json => @interviewer_task
	end

	def destroy
		render :json => @client._delete({}, "/#{params[:id]}")
	end
end