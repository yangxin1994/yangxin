# encoding: utf-8
require 'array'
require 'error_enum'
require 'quill_common'
class Sample::SurveysController < ApplicationController

  #############################
  #功能:用户点击“立即参与”，获取最新的热点小调查
  #http method：get
  #传入参数: 无
  #返回的参数:调查问卷的id
  #############################	
  def get_hot_spot_survey
    #查询条件:必须是发布在社区的调查问卷，必须是热点小调查，必须是已经发布的问卷,必须是可推广的调查问卷
    @survey = Survey.where(:quillme_promote => true,:quillme_hot => true,:spreadable => true,:status => 2).first
    render_json { @survey }
  end

  #############################
  #功能:用户点击“立即参与”，获取最新的热点小调查
  #http method：get
  #传入参数: 无
  #返回的参数:一个盛放推荐调研问卷的列表
  #############################	
  def get_recommends
    @surveys = Survey.where(:quillme_promote => true,:spreadable => true,:status => 2)
    @surveys = auto_paginate(@surveys)
    render_json { @surveys }
  end



end
