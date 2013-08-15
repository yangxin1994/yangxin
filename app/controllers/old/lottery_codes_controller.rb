# coding: utf-8

class LotteryCodesController < ApplicationController
	def show
		# @lottery_code = LotteryCode.find_by_id params[:id]
		# render_json @lottery_code.is_valid? do |s|
		# 	@lottery_code[:prize] = @lottery_code.prize if s && [2, 4].include?(@lottery_code.status)
		# 	@lottery_code[:lottery_status] = @lottery_code.lottery.status
		# 	@lottery_code
		# end
		LotteryCode.find_by_id params[:id] do |lottery_code|
			render_json false do
				# lottery_code[:prize] = lottery_code.prize [2, 4].include?(lottery_code.status)
				# lottery_code[:lottery_status] = lottery_code.lottery.status
				success_true
				lottery_code.present_quillme_draws
			end
		end
	end
end
