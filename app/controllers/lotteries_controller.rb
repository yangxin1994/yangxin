# coding: utf-8

class LotteriesController < ApplicationController

	def index
		@lotteries = Lottery.activity.page(page)
		@lotteries = ErrorEnum::LotteryNotFound if @lotteries.empty?
		respond_to do |format|
			format.html
			format.json { render json: @lotteries}
		end
	end
	
	def draw
		@result = LotteryCode.find_by_id params[:id] do |r|
				r.draw
			end
		respond_to do |format|
				format.json {render json: @result }
		end
	end
	# def_each :virtualgoods, :cash, :realgoods, :stockout do |method_name|
	# 	@gifts = Gift.send(method_name).can_be_rewarded.page(page)
	# 	@gifts = ErrorEnum::GiftNotFound if @gifts.empty? 
	# 	respond_to do |format|
	# 		#format.html 
	# 		format.json { render json: @gifts}
	# 	end
	# end
	
end