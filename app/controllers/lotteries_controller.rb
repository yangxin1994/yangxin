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
	# 	@presents = Present.send(method_name).can_be_rewarded.page(page)
	# 	@presents = ErrorEnum::PresentNotFound if @presents.empty? 
	# 	respond_to do |format|
	# 		#format.html 
	# 		format.json { render json: @presents}
	# 	end
	# end
	
end