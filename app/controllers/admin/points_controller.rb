# encoding: utf-8
class Admin::PointsController < Admin::ApplicationController
  def operate
    @point_log = current_user.operate_point(params[:operate_point], params[:user_id])
    respond_and_render_json(!@point_log.invalid?) do
    	@point_log.as_retval
    end
  end
end