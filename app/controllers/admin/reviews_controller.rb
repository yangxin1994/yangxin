class Admin::ReviewsController < ApplicationController

	layout :layout_select
	before_filter :get_client, :is_survey_auditor

	def layout_select
		is_admin ? 'admin_new' : 'survey_auditor'
	end

	def is_survey_auditor
		has_role(8) || has_role(16)
	end

	private :layout_select, :is_survey_auditor

	def get_client
		@client = BaseClient.new(session_info, "/survey_auditor/surveys")
	end

	#********************
	
	def index
		@reviews = @client._get({
				:page => page,
				:per_page => per_page
			})	
		_sign_out and return if @reviews.require_login?

		respond_to do |format|
			format.html
			format.json { render json: @reviews}
		end
	end

	# PUT:
	def publish
		hash_params = {}
		hash_params.merge!({message: params[:message]}) if params[:message]
		render :json => @client._get(hash_params,"/#{params[:id]}/publish")
	end

	# PUT
	def reject
		hash_params = {}
		hash_params.merge!({message: params[:message]}) if params[:message]
		render :json => @client._get(hash_params,"/#{params[:id]}/reject")
	end

	# PUT
	def close
		render :json => @client._get({},"/#{params[:id]}/close")
	end

	# PUT
	def pause
		render :json => @client._get({},"/#{params[:id]}/pause")
	end

end