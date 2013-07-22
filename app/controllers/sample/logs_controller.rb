# encoding: utf-8
class Sample::LogsController < ApplicationController

  #############################
  #功能:获取最新的动态信息来作为新鲜事显示
  #http method：get
  #传入参数: 无
  #返回的参数:一个盛放新鲜事的列表
  #############################	
  def fresh_news
    @logs = Log.get_new_logs(params[:limit],params[:type])
  	render_json_auto(@logs)
  end


  #############################
  #功能:获取惩罚公示板
  #http method：get
  #############################
  #功能:获取惩罚公
  #传入参数: 无
  #返回的参数:记录惩罚的列表
  ############################# 
  def get_disciplinal_news
    @logs = Log.get_new_logs(3,64)
    render_json_auto(@logs)
  end


  def get_newst_exchange_logs
    @logs = Log.get_newst_exchange_logs
    render_json { @logs }          
  end

  def get_point_change_log
    if params[:scope].present? && params[:scope] == 'in'
      @logs = Log.where(:type => 8,:user_id => @current_user.id, 'data.amount.gt' => 0).desc(:created_at).page(params[:page]).per(params[:per_page])
    elsif params[:scope].present? && params[:scope] == 'out' 
      @logs = Log.where(:type => 8,:user_id => @current_user.id, 'data.amount.lt' => 0).desc(:created_at).page(params[:page]).per(params[:per_page])  
    else
      @logs = Log.where(:type => 8,:user_id => @current_user.id).desc(:created_at).page(params[:page]).per(params[:per_page]) 
    end
    
    render_json_auto auto_paginate @logs
  end




end