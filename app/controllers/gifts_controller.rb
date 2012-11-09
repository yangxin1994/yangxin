# coding: utf-8
class GiftsController < ApplicationController
  #TO DO before_filter
  # gifts.json?page=1

  def index
    render_json { auto_paginate(Gift) }
  end

  def_each :virtual, :cash, :entity do |method_name|
    @gifts = auto_paginate(Gift.send(method_name))
    render_json { @gifts }
  end

  def show
    @gift = Gift.find_by_id(params[:id])
    @gift[:photo_src] = @gift.photo.picture_url
    render_json { @gift }
  end
  
end
