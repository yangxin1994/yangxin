class Quill::QuotasController < Quill::QuillController
	
	before_filter :get_ws_client, :only => [:destroy, :update, :create, :refresh]
	
	def get_ws_client
		@ws_client = Quill::QuotaClient.new(session_info, params[:questionaire_id])
	end

	# AJAX: destory a quota by its index
	def destroy
		render :json => @ws_client.remove(params[:id].to_i)
	end

	# AJAX: update s quota by its index
	def update
		render :json => @ws_client.update(params[:id].to_i, params[:quota])
	end

	# AJAX: create a new quota
	def create
		render :json => @ws_client.create(params[:quota])
	end

	# AJAX: refresh quotas stat
	def refresh
		render :json => @ws_client.refresh
	end
	
end