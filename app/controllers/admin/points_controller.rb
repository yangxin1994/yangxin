# encoding: utf-8
class Admin::PointsController < Admin::ApplicationController
	before_filter :require_user_exist	
  def operate

  	Logger.new("log/test.log").info("sdfsdfds#{current_user}")
    @point_log = @current_user.operate_point(params[:operate_point], params[:user_id])
    puts @point_log.as_retval
    respond_to do |format|
      format.json { render json: @point_log.as_retval }
    end
  end
  
end