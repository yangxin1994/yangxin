class Admin::RewardsController < Admin::AdminController
  before_filter :require_sign_in

  before_filter :get_rewards_client
  
  def get_rewards_client
    @rewards_client = Admin::RewardClient.new(session_info)
  end

  def operate_point
    render json: @rewards_client.operate_point(params[:point], params[:user_id])
  end
  
 end