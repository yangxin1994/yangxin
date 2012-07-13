class PointsController < ApplicationController
	#TODO before_filter
	def index
		@point_logs = current_user.point_logs.page(params[:page].to_i)
		respond_to do |format|
			format.json { render json: @point_logs }
		end
	end
end