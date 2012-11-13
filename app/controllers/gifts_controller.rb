# coding: utf-8
class GiftsController < ApplicationController
  #TO DO before_filter
  # gifts.json?page=1

  def index
    render_json { auto_paginate(Gift) }
  end

  def_each :virtual, :cash, :entity, :lottery do |method_name|
    @gifts = auto_paginate(Gift.send(method_name))
    render_json { @gifts }
  end

  def show
    @gift = Gift.find_by_id(params[:id])
    @gift[:photo_src] = @gift.photo.picture_url
    render_json { @gift }
  end
  
  def exchange
    @gift = Gift.find_by_id(params[:id])
    render_json @gift.is_valid? &&
                @gift.point > user.point &&
                @gift.surplus >= 0 do |s|
      if s
        if @gift.point > user.point 
          user.orders.create(:gift => @gift,
                             :type => @gift.type) 
        elsif @gift.surplus <= 0
          return ErrorEnum::GIFT_NOT_ENOUGH
        else
          return ErrorEnum::POINT_NOT_ENOUGH
        end
      else
        return ErrorEnum::GIFT_NOT_FOUND
      end
    end
  end

end
