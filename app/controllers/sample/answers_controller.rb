# encoding: utf-8
require 'array'
require 'error_enum'
require 'quill_common'
class Sample::AnswersController < ApplicationController

  #############################
  #功能:获取今日累计答题数
  #http method：get
  #传入参数: 无
  #返回的参数:答题的数量
  #############################	
  def get_today_answers_count
    date = Date.today
    today_start = Time.utc(date.year, date.month, date.day)
    today_end = Time.utc(date.year, date.month, date.day+1)
    @survey = Answer.where(:created_at.gte => today_start,:created_at.lt => today_end).count
    render_json { @survey }
  end

  #############################
  #功能:获取今日分享问卷数
  #http method：get
  #传入参数: 无
  #返回的参数:答题的数量
  ############################# 
  def get_today_spread_count
    date = Date.today
    today_start = Time.utc(date.year, date.month, date.day)
    today_end = Time.utc(date.year, date.month, date.day+1)
    @survey = Answer.where(:created_at.gte => today_start,:created_at.lt => today_end,:introducer_id.ne => nil).count
    render_json { @survey }
  end  

end
