# coding: utf-8
class Sample::ConnectsController < Sample::SampleController
  def show
    if params[:code].present? || params[:is_success].present?  # params[:is_success] use for alipay
      data = ThirdPartyUser.get_access_token(
        account: params[:id], 
        param_obj: params, 
        redirect_uri: social_redirect_uri(params[:id])
      )
      result = ThirdPartyUser.find_or_create_user(params[:id],data,@current_user)
      unless current_user.present?
        if result.user.login(request.remote_ip,params[:id])
          refresh_session(result.user.auth_key)
          redirect_to root_path
        else
          redirect_to root_path
        end
      else
        redirect_to setting_bindings_users_path
      end
    else
      redirect_to root_path
    end
    
  end
end