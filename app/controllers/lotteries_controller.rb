# coding: utf-8

class LotteriesController < ApplicationController
	before_filter :require_sign_in, :only => [:own, :draw]
	def index
		render_json do
			auto_paginate Lottery.quillme do |lotteries|
				lotteries.present_json("quillme")
			end 
		end
	end
	
	def own
		logger.info "==== #{current_user}======="
		retval = {}
		render_json do
			[:for_draw, :drawed_w, :drawed_f].each do |scope|
				params[:page] = params["#{scope.to_s}_p".to_sym].to_i
				retval[scope] = auto_paginate(current_user.lottery_codes.send(scope)) do |lottery_codes|
					lottery_codes.present_json("quillme")
				end
			end
			retval
		end
	end

	def draw
		@lottery_code = current_user.lottery_codes.for_draw.find_by_id params[:id]
		render_json @lottery_code.is_valid? do |s|
			# 直接找不到抽奖号比较好? 或者提示抽过奖了 ?
			if !s
				@lottery_code.as_retval
	       # binding.pry
			elsif @lottery_code.lottery.status != 3
				@is_success = false
				{:error_code => ErrorEnum::INVALID_LOTTERYCODE_ID,
	       :error_message => "Lottery not activity"}
	       # binding.pry
			else
				@lottery_code.draw
			end
		end
	end

	def exchange
		render_json false do |s|
			Lottery.find_by_id params[:id] do |lottery|
				if lottery.exchange(current_user)
					success_true 
				else
					{
						"error_code" => ErrorEnum::LOTTERY_CANNOT_EXCHANGE,
						"error_message" => "lottery couldn't exchang"
					}
				end
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
	 def show
    # TODO is owners request?
    # @lottery = Lottery.find_by_id(params[:id])
    # @lottery[:photo_src] = @lottery.photo.picture_url unless @lottery.photo.nil?
    # @lottery[:prizes] = @lottery.prizes
    render_json false do
    	Lottery.find_by_id(params[:id]) do |lottery|
    		success_true
    		lottery.present_quillme
    	end
    end
  end
end