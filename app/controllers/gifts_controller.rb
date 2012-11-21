# coding: utf-8
class GiftsController < ApplicationController
  #TO DO before_filter
  # gifts.json?page=1
  before_filter :require_sign_in, :only => :exchange
  def index
    render_json do 
      auto_paginate(Gift.can_be_rewarded) do |g|
        g.page(page).per(per_page).map { |e| e[:photo_src] = e.photo.nil? ? nil : e.photo.picture_url; e  }
      end
    end
  end

  def_each :virtual, :cash, :entity, :lottery do |method_name|
    @gifts = auto_paginate(Gift.can_be_rewarded.send(method_name)) do |g|
      g.page(page).per(per_page).map { |e| e[:photo_src] = e.photo.nil? ? nil : e.photo.picture_url; e  }
    end
    render_json { @gifts }
  end

  def show
    @gift = Gift.find_by_id(params[:id])
    @gift[:photo_src] = @gift.photo.nil? ? nil : @gift.photo.picture_url 
    render_json { @gift }
  end
  
  def exchange
    @gift = Gift.find_by_id(params[:id])
    render_json @gift.is_valid? &&
                @gift.point > current_user.point &&
                @gift.surplus >= 0 do |s|
      order = params[:order].merge({:gift => @gift, :type => @gift.type})
      if s
        if @gift.point > current_user.point 
          current_user.orders.create(order) 
        elsif @gift.surplus <= 0
          return ErrorEnum::GIFT_NOT_ENOUGH
        else
          return ErrorEnum::POINT_NOT_ENOUGH
        end
      else
        if @gift.surplus <= 0
          return ErrorEnum::GIFT_NOT_ENOUGH
        else
          return ErrorEnum::GIFT_NOT_FOUND
        end
      end
    end
  end

end
