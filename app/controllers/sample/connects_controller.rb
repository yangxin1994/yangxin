# coding: utf-8
class Sample::ConnectsController < Sample::SampleController
  def show
    if params[:code].present?
      data = ThirdPartyUser.get_access_token(
        account: params[:id], 
        param_obj: params, 
        redirect_uri: social_redirect_uri(params[:id])
      )
      Rails.logger.info("--------------------------")
      Rails.logger.info(data['error_response'])
      Rails.logger.info("--------------------------")
      result = ThirdPartyUser.find_or_create_user(params[:id],data,@current_user)
      unless current_user.present?
        if result.user.login(request.remote_ip,params[:id])
          refresh_session(result.user.auth_key)
          #redirect_to root_path
        else
          redirect_to sign_in_account_path
        end
      else
        redirect_to setting_users_path
      end
    else
      redirect_to sign_in_account_path
    end
    
  end
end