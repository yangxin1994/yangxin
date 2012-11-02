# coding: utf-8

class LotteriesController < ApplicationController

	def index
		respond_and_render_json { Lottery.activity.page(page) }
	end
	
	def draw
		respond_and_render_json do
			LotteryCode.find_by_id params[:id] do |r|
				r.draw
			end
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