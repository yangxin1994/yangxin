# coding: utf-8
class GiftsController < ApplicationController
  #TO DO before_filter
  # gifts.json?page=1

  def index
    render_json { Gift.can_be_rewarded.page(page).per(per_page) }
  end

  def_each :virtual, :cash, :entity, :stockout, :expired do |method_name|
    @gifts = Gift.send(method_name).can_be_rewarded.page(page).per(per_page)
    render_json { @gifts}
  end

  def show
    # TO DO is owners request?
    render_json { Gift.find_by_id(params[:id]) }
  end
  
end
