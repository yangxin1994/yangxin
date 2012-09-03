# encoding: utf-8
class Admin::PointsController < Admin::ApplicationController
	before_filter :require_user_exist	
  def operate
    @point_log = current_user.operate_point(params[:operate_point], params[:user_id])
    p @point_log
    respond_and_render_json(@point_log.valid?) do
    	@point_log.as_retval
    end
  end
end