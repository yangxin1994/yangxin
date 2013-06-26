# encoding: utf-8
class Sample::PublicNoticesController < ApplicationController

  #############################
  #功能: 按照时间，获取最新的公告信息
  #http method：get
  #传入参数: page(页数)，如果不需要分页的话，这个参数可以不传
  #可能返回的参数:一个盛放公告的列表
  #############################		
  def get_newest
  	@public_notices = PublicNotice.desc(:updated_at)
  	@public_notices = auto_paginate(@public_notices)
  	render_json { @public_notices }
  end
end