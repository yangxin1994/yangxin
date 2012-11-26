class Admin::RewardLogsController < ApplicationController
	before_filter :require_sign_in
	def for_points
		if params[:uid]
			@user = User.find_by_id(params[:uid])
			render_json @user.valid? do |s|
				if s
					auto_paginate(@user.reward_logs.point_logs)
				else
					@user.as_retval
				end
			end
		else
			render_json do
				auto_paginate(LotteryLogs.point_logs)
			end
		end
	end

	def for_lotteries
		if params[:uid]
			@user = User.find_by_id(params[:uid])
			render_json @user.is_valid? do |s|
				if s
					auto_paginate(@user.reward_logs.lottery_logs)
				else
					@user.as_retval
				end
			end
		else
			render_json do
				auto_paginate(LotteryLogs.point_logs)
			end
		end
	end

	def index
		if params[:user_id]
			@user = User.find_by_id(params[:user_id])
			render_json @user.is_valid? do |s|
				if s
					case params[:type]
					when 1
						auto_paginate(@user.reward_logs.lottery_logs)
					when 2
						auto_paginate(@user.reward_logs.point_logs)
					else
						auto_paginate(@user.reward_logs)
					end
				else
					@user.as_retval
				end
			end
		else
			render_json do
				auto_paginate(LotteryLogs.all)
			end
		end
	end
end