class Admin::RewardsController < Admin::ApplicationController
	before_filter :find_user_exist

	def find_user_exist
		@user = User.find_by_id_including_deleted(params[:uid] || params[:user_id])
		return ErrorEnum::USER_NOT_EXIST unless @user
	end

	private :find_user_exist

	# ******************************

	# def for_points
	# 	render_json { auto_paginate(@user.reward_logs.point_logs)}
	# end

	# def for_lotteries
	# 	render_json { auto_paginate(@user.reward_logs.lottery_logs)}
	# end

	# def index
	# 	render_json { auto_paginate(@user.reward_logs)}
	# end

	def operate_point
		@reward_log = @current_user.operate_point(params[:point], params[:uid] || params[:user_id])
		render_json(@reward_log.valid?) do
			@reward_log.as_retval
		end
	end
end