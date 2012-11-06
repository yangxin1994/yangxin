# coding: utf-8
class GiftsController < ApplicationController
  #TO DO before_filter
  # gifts.json?page=1

  def index
    respond_and_render_json { Gift.can_be_rewarded.page(page).per(per_page) }
  end


  def_each :virtualgoods, :cash, :realgoods, :stockout, :expired do |method_name|
    @gifts = Gift.send(method_name).can_be_rewarded.page(page).per(per_page)
    respond_and_render_json { @gifts}
  end

  def show
    # TO DO is owners request?
    respond_and_render_json { Gift.find_by_id(params[:id]) }
  end
  
end
