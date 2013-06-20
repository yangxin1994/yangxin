# encoding: utf-8
class Admin::GiftsController < Admin::ApplicationController

  def check_gift_existence
    @gift = Gift.find_by_id(params[:id])
    render_json_auto(ErrorEnum::GIFT_NOT_EXIST) and return if @gift.nil?
  end

  def index
    @gifts = Gift.search_gift(params[:title], params[:status].to_i, params[:type].to_i)
    render_json_auto(auto_paginate(@gifts)) and return
  end

  def create
  end

  def update
  end

  def destroy
    render_json_auto(@gift.delete_gift) and return
  end
end