# encoding: utf-8
class Sample::LogsController < ApplicationController

  #############################
  #功能:获取最新的动态信息来作为新鲜事显示
  #http method：get
  #传入参数: 无
  #返回的参数:一个盛放新鲜事的列表
  #############################	
  def fresh_news
    @logs = Log.where(:type => 8).any_of({'data.reason' => 1},{'data.reason' => 2},{'data.reason' => 4}).desc(:updated_at).limit(5)
  	render_json { @logs }
  end


  #############################
  #功能:获取惩罚公示板
  #http method：get
  #传入参数: 无
  #返回的参数:记录惩罚的列表
  ############################# 
  def get_disciplinal_news
    @logs = Log.where(:type => 8,'data.reason' => 16).desc(:created_at).limit(3)
    render_json { @logs }
  end


  def get_newst_exchange_logs
    @logs = Log.where(:type => 4,'data.reason' => 8).desc(:updated_at).limit(5)
    render_json { @logs }          
  end




end