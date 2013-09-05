class AdvertisementsController < ApplicationController

	before_filter :get_client

	def get_client
		@client = BaseClient.new(session_info, "/advertisements")
	end

	# *******************************

	# # GET
	# def index
	# 	hash_params={:page=> page, :per_page => per_page}
	# 	hash_params.merge!({:activate => params[:activate].to_s == "true"}) if params[:activate]
	# 	@advertisements = @client._get(hash_params)

	# 	respond_to do |format|
	# 		format.html
	# 		format.json { render json: @advertisements}
	# 	end
	# end

	# # GET
	# def show
	# 	@advertisement = @client._get({},"/#{params[:id]}")
	# 	respond_to do |format|
	# 		format.html
	# 		format.json { render json: @advertisement}
	# 	end
	# end

end