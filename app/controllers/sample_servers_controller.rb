# encoding: utf-8
class SampleServersController < ApplicationController

  def create
    survey_data = {
      survey_title: params[:survey_title],
      survey_id: params[:survey_id],
      survey_url:params[:survey_url],
      survey_deadline:params[:survey_deadline],
      survey_quota: params[:survey_quota]
    }

    sample_server = SampleServer.find_by_survey_id(params[:survey_id])
    if sample_server.present?
      render_json_auto SampleServer.update(survey_data) and return
    else
      render_json_auto SampleServer.create(survey_data) and return
    end

  end

end