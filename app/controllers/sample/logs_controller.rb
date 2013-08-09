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
    logs = PunishLog.desc(:created_at).limit(3).map do |log|
      log['avatar'] = log.user.avatar.present? ? log.user.avatar.picture_url : User::DEFAULT_IMG
      log['username'] = log.user.try(:nickname)
      log
    end
    render_json_auto logs
  end


  def get_newst_exchange_logs
    @logs = Log.get_newst_exchange_logs
    render_json { @logs }          
  end

  def find_lottery_logs
    render_json_auto  LotteryLog.find_lottery_logs(params[:id],params[:status],params[:limit])
  end

  def get_point_change_log
    if params[:scope] == 'in'
      @logs = PointLog.where(:user_id => @current_user.id, :amount.gt => 0)
    elsif params[:scope] == 'out' 
      @logs = PointLog.where(:user_id => @current_user.id, :amount.lt => 0)
    else
      @logs = PointLog.where(:user_id => @current_user.id)
    end
    @paginated_logs = auto_paginate @logs.desc(:created_at) do |paginated_logs|
      paginated_logs.map { |e| e.info_for_sample }
    end
    render_json_auto @paginated_logs
  end
end