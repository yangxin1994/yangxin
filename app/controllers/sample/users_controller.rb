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
  	@users = User.sample.where(:is_block => false,:username.ne => "",:username.exists => true).desc(:point).limit(5)
    @users = @users.map{|user| user['spread_count'] = user.spread_count;user['answer_count'] = user.answers.not_preview.count;user['avatar_src']= user.avatar? ? user.avatar.picture_url : nil;user}
    render_json { @users }
  end

  

end