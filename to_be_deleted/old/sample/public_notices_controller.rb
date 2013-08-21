# encoding: utf-8
class Sample::PublicNoticesController < ApplicationController

  #############################
  #功能: 按照时间，获取最新的公告信息
  #http method：get
  #传入参数: page(页数)，如果不需要分页的话，这个参数可以不传
  #可能返回的参数:一个盛放公告的列表
  #############################		
  def get_newest
    @public_notices = auto_paginate PublicNotice.opend.desc(:updated_at)
    render_json_auto @public_notices and return
  end

  def show
    @public_notice = PublicNotice.find(params[:id])
    pids = PublicNotice.where(:status => 2).desc(:updated_at)
    if pids.present?
      tmp_hash = {}
      pids.each_with_index do |pid,index|
        tmp_hash["#{pid['_id']}"] = index
      end
    end
    tmp_hash['current_notice'] = @public_notice
    render_json { tmp_hash }
  end

end