# coding: utf-8

class LotteryCodesController < ApplicationController
	def show
		@lottery_code = LotteryCode.find_by_id params[:id]
		render_json @lottery_code.is_valid? do
			@lottery_code.as_retval
		end
	end
end
