# encoding: utf-8
require 'error_enum'
class Sample::UsersController < ApplicationController

  #############################
  #功能:用户点击“立即参与”，获取最新的热点小调查
  #http method：get
  #传入参数: 无
  #返回的参数:一个盛放排行榜用户的列表
  #############################		
  def get_top_ranks
  	@users = User.only(:point,:username).sample.where(:is_block => false,:username.ne => "",:username.exists => true).desc(:point).limit(5)
    #某个样本完成答题的个数，3代表完成
    #u.answers.where(:status => 3).count
    #某个样本推广的个数
    #u.get_introduced_users.size
    render_json { @users }
  end
end