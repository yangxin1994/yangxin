class Admin::RewardSchemesController < Admin::AdminController

  before_filter :get_client

  layout "layouts/admin-todc"

  def get_client
    @client = Admin::RewardSchemeClient.new(session_info)
  end

  # *****************************

  def create
    result = @client.create(params[:reward_scheme])
    if result.success
      @reward_scheme = result
      redirect_to "#{reward_schemes_admin_path(:id => params[:reward_scheme][:survey_id])}"
    else
      render result
    end
  end

  def update
    result = @client.update(params[:reward_scheme])
    if result.success
      @reward_scheme = result
      redirect_to "#{reward_schemes_admin_path(:id => params[:reward_scheme][:survey_id])}?editing=#{params[:id]}"
    else
      render result
    end
  end

  def destroy
    result = @client.destroy(params)
    render :json => {:success => result.success}
  end

end