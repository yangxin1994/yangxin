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
    @gifts = Gift.desc("#{sort_type}").page(params[:page]).per(params[:per_page])
    @gifts = @gifts.map{|g| g['photo'] = g.photo.nil? ? nil : g.photo.picture_url;g}
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
    @gift[:photo_src] = @gift.photo.nil? ? nil : @gift.photo.picture_url 
    render_json { @gift }
  end

  	
end