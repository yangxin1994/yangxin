class Carnival::CampaignsController < Carnival::CarnivalController
  def index
    if @current_carnival_user.blank?
      @current_carnival_user = CarnivalUser.create_new(params[:introducer_id])
      cookies[:carnival_user_id] = carnival_user.id.to_s
    end
  end
end