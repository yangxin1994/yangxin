# coding: utf-8

class LotteriesController < ApplicationController

	def index
		render_json do
			auto_paginate Lottery.activity do 
				Lottery.activity.page(page).per(per_page).map do |e|
					e[:photo_src] = e.photo.picture_url unless e.photo.nil?
					e
				end
			end 
		end
	end
	
	def own
		render_json do
			[:for_draw, :drawed_w].map do |s|
				pl = params["#{s.to_s}_p".to_sym].to_i || 1
				pl = 1 if pl <= 0
				lc = auto_paginate current_user.lottery_codes.send(s) do
						current_user.lottery_codes.send(s).page(pl).per(per_page).map do |e|
						e[:for_lottery] = e.lottery.presence
						e[:for_lottery][:photo_src] = e.lottery.photo.picture_url unless e.lottery.photo.nil?
						e
					end
				end
				lc["current_page"] = pl
				lc["previous_page"] = (pl - 1 > 0 ? pl-1 : 1)
	  		lc["next_page"] = (pl+1 <= lc["total_page"] ? pl+1: lc["total_page"])
	  		lc
			end
		end
	end

	def draw
		render_json do
			# 直接找不到抽奖号比较好? 或者提示抽过奖了 ?
			current_user.lottery_codes.for_draw.find_by_id params[:id] do |r|
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
	 def show
    # TODO is owners request?
    @lottery = Lottery.find_by_id(params[:id])
    @lottery[:photo_src] = @lottery.photo.picture_url unless @lottery.photo.nil?
    render_json { @lottery}
  end
end