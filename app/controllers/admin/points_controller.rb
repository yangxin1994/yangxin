class Admin::PointsController < Admin::ApplicationController
	before_filter :require_user_exist	
  def operate
    @reward_log = current_user.operate_point(params[:operate_point], params[:user_id])
    p @reward_log
    respond_and_render_json(@reward_log.valid?) do
    	@reward_log.as_retval
    end
  end
end