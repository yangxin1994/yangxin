class PointsController < ApplicationController
	before_filter :require_sign_in
	def index
		respond_and_render_json {current_user.point_logs.page(page)}
	end
end