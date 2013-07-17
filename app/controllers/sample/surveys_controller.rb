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
    @hot_survey = Survey.only('_id','title').quillme_promote.quillme_hot.opend.first
    render_json { @hot_survey }
  end

  #############################
  #功能:获取推荐的调研列表
  #http method：get
  #传入参数: 
  #    page 当前页数
  #    per_page 每页显示多少条
  #    status 开放状态 1表示关闭 2表示开放中
  #    在首页的时候，不许要传递status
  #在列表页的时候，开放中的问卷、已结束的问卷都要传递status，值分别对应2和1
  #返回的参数:一个盛放推荐调研问卷的列表
  #############################	
  # def get_recommends
  #   status = params[:status].present?  ? params[:status] : nil
  #   @surveys = Survey.get_recommends(params[:page],params[:per_page],status,current_user)
  #   if !params[:status].present?
  #     @surveys = @surveys.slice!(0,2)     
  #     #@surveys = auto_paginate(@surveys)
  #   else
  #     @surveys.shift
  #   end
  #   render_json_auto(@surveys)
  # end


  def get_recommends
    # status 1 or 2
    #reward_type should be [1,2]
    surveys = Survey.get_recommends(params[:status],params[:reward_type])
    survey_obj = auto_paginate(surveys) do |paginated_surveys|
      paginated_surveys.map { |e| e.excute_sample_data(@current_user) } 
    end
    render_json_auto survey_obj
  end

  def show
    @survey = Survey.find_by_id(params[:id])
    render_json { @survey }
  end

  def list_spreaded_surveys
    render_json_auto ErrorEnum::REQUIRE_LOGIN if @current_user.nil?
    surveys_with_spreaded_number = Survey.list_spreaded_surveys(@current_user)
    paginated_surveys = auto_paginate surveys_with_spreaded_number
    render_json_auto(paginated_surveys)
  end

end
