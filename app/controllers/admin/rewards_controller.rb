class Admin::RewardsController < Admin::ApplicationController
	before_filter :require_user_exist	
  def operate_point
    @reward_log = current_user.operate_point(params[:point], params[:id])
    render_json(@reward_log.valid?) do
    	@reward_log.as_retval
    end
  end
end