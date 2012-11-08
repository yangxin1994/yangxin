class PointsController < ApplicationController
	before_filter :require_sign_in
	def index
		respond_and_render_json { auto_paginate(current_user.reward_logs.point_logs)}
	end
end