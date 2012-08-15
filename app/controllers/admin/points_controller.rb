# encoding: utf-8
class Admin::PointsController < Admin::ApplicationController
  def operate
    @point_log = current_user.operate_point(params[:operate_point], params[:user_id])
    respond_to do |format|
      format.json { render json: @point_log.as_retval }
    end
  end
  
end