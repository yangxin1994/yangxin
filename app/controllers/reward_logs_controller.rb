class RewardLogsController < ApplicationController
	before_filter :require_sign_in
	def for_points
		render_json { auto_paginate(current_user.reward_logs.point_logs)}
	end

	def for_lotteries
		render_json { auto_paginate(current_user.reward_logs.lottery_logs)}
	end

	def index
		render_json { auto_paginate(current_user.reward_logs)}
	end
end