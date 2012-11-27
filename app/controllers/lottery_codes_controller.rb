# coding: utf-8

class LotteryCodesController < ApplicationController
	def show
		@lottery_code = LotteryCode.find_by_id params[:id]
		render_json @lottery_code.is_valid? do |s|
			@lottery_code[:prize] = @lottery_code.prize if s && [2, 4].include?(@lottery_code.status)
			@lottery_code.as_retval
		end
	end
end
