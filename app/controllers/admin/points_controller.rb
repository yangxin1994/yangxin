# encoding: utf-8
class Admin::PointsController < Admin::ApplicationController
  def operate
    @point_log = current_user.operate_point(params[:operate_point])
    respond_to do |format|
      format.json { render json: @point_log.invild? ? @point_log.error_code : @point_log }
    end
  end
end