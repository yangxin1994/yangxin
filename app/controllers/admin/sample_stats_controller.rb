class Admin::SampleStatsController< Admin::AdminController
  layout "layouts/admin_new"

	before_filter :require_sign_in
	before_filter :require_admin
  before_filter :get_client

  def index
    @sample_count = @client.get_sample_count.value
    data = @client.get_sample_count('day', 2).value['new_sample_number']
    @new_user_by_day = data[1] - data[0]
    data = @client.get_sample_count('week', 2).value['new_sample_number']
    @new_user_by_week = data[1] - data[0]
    data = @client.get_active_sample_count('day', 1).value
    @active_user_by_day = data[0]
    data = @client.get_active_sample_count('week', 1).value
    @active_user_by_week = data[0]
  end

  def get_sample_count
    render json: @client.get_sample_count(params[:period], params[:time_length]).value
  end

  def get_active_sample_count
    render json: @client.get_active_sample_count(params[:period], params[:time_length]).value
  end

  private
  def get_client
    @client = Admin::SampleClient.new(session_info)
  end
end
