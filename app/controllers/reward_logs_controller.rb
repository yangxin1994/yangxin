class RewardLogsController < ApplicationController
	before_filter :require_sign_in
	def for_points
		#render_json { auto_paginate(current_user.reward_logs.point_logs)}
		render_json do
			auto_paginate(current_user.reward_logs.point_logs) do |logs|
				logs.map do |log|
					log[:order_id] = RewardLog.find_by_id(log[:ref]).order_id unless log[:ref].nil?		
					log
				end
			end
		end
	end

	def for_lotteries
		render_json { auto_paginate(current_user.reward_logs.lottery_logs)}
	end

	def index
		render_json { auto_paginate(current_user.reward_logs)}
	end
end