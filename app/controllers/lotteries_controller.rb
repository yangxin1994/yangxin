# coding: utf-8

class LotteryController < ApplicationController

	def index
		@lotteries = Lottery.activity.page(page)
		@lotteries = ErrorEnum::LotteryNotFound if @lotteries.empty?
		respond_to do |format|
			format.html
			format.json { render json: @lotteries}
		end
	end

	# def_each :virtualgoods, :cash, :realgoods, :stockout do |method_name|
	# 	@presents = Present.send(method_name).can_be_rewarded.page(page)
	# 	@presents = ErrorEnum::PresentNotFound if @presents.empty? 
	# 	respond_to do |format|
	# 		#format.html 
	# 		format.json { render json: @presents}
	# 	end
	# end
	
end