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
    @hot_survey = Survey.quillme_promote.quillme_hot.opend.first
    render_json { @hot_survey }
  end


  def get_recommends
    # status 1 or 2
    #reward_type should be [1,2]
    surveys = Survey.get_recommends(params[:status],params[:reward_type],params[:answer_status],@current_user,params[:home_page])
    survey_obj = auto_paginate(surveys) do |paginated_surveys|
      paginated_surveys.map { |e| e.excute_sample_data(@current_user) } 
    end
    render_json_auto survey_obj
  end

  def get_reward_type_count
    data_obj = Survey.get_reward_type_count(params[:status])
    render_json_auto data_obj
  end


  def show
    @survey = Survey.find_by_id(params[:id])
    render_json { @survey }
  end

  def list_spreaded_surveys
    render_json_auto ErrorEnum::REQUIRE_LOGIN if @current_user.nil?
    surveys_with_spreaded_number = auto_paginate @current_user.survey_spreads.desc(:created_at) do |paginated_survey_spreads|
      paginated_survey_spreads.map do |e|
        e.survey.info_for_sample.merge({"spread_number" => e.times})
      end
    end
    render_json_auto surveys_with_spreaded_number and return
  end

	def estimate_answer_time
		survey = Survey.normal.find_by_id(params[:id])
		respond_to do |format|
			format.json	{ render_json_auto(survey.nil? ? ErrorEnum::SURVEY_NOT_EXIST : survey.estimate_answer_time) and return }
		end
	end

end
