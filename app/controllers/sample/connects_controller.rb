class Sample::ConnectsController < Sample::SampleController
  def show
    Rails.logger.info("--------------------------------")
    Rails.logger.info(params.inspect)
    Rails.logger.info("--------------------------------")

    if params[:code].present?
      ThirdPartyUser.get_access_token(params[:id], params[:code], social_redirect_uri(params[:id]))
      if result.success
        if !result.value['auth_key'].blank?
          refresh_session(result.value['auth_key'])
        elsif !result.value['third_party_user_id'].blank?
          param_i = params[:i].blank? ? '' : "&i=#{params[:i]}"
          redirect_to "#{signup_path}?tpui=#{result.value['third_party_user_id']}#{param_i}"  and return
        end
      end
    end
    redirect_to signin_path and return
  end
end