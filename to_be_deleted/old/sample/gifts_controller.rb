# encoding: utf-8
class Sample::GiftsController < ApplicationController

  #############################
  #功能:获取热门兑换礼品列表
  #http method：get
  #传入参数: page(页数)，如果不需要分页的话，这个参数可以不传
  #可能返回的参数:一个盛放礼品的列表
  #############################		
  def hotest
    sort_type = params[:sort_type].present? ? params[:sort_type]  : 'exchange_count' 
    @gifts = Gift.find_real_gift(sort_type)
    @gifts = auto_paginate @gifts
    render_json_auto(@gifts)
  end

  #############################
  #功能:获取热门兑换礼品
  #http method：get
  #传入参数: 礼品的id
  #可能返回的参数:一个具体的礼品对象
  #############################		
  def show
    @gift = Gift.find_by_id(params[:id])
    @gift[:photo_src] = @gift.photo.nil? ? Gift::DEFAULT_IMG : @gift.photo.picture_url 
    render_json { @gift }
  end

  	
end