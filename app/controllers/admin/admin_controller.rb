class Admin::AdminController < ApplicationController
  
  layout "admin"

  before_filter :require_sign_in
  # because only user_id of user is from return data in many times.
  # so add get_email method to replace user_id to email by AJAX.
  before_filter :require_admin, :except => [:get_email]

  def require_admin
    # if !is_admin  # is_admin only check admin and super admin.
    # if is_only_normal_user
    #   respond_to do |format|
    #     format.html { redirect_to signin_path and return }
    #     format.json { render :json => Common::ResultInfo.error_require_login and return }
    #   end
    # elsif !is_admin
    #   if has_role(QuillCommon::UserRoleEnum::SURVEY_AUDITOR)
    #     redirect_to survey_auditor_path and return
    #   elsif has_role(QuillCommon::UserRoleEnum::ANSWER_AUDITOR)
    #     redirect_to admin_review_answers_path and return
    #   end
    # end
    # return true

    if has_role(QuillCommon::UserRoleEnum::ANSWER_AUDITOR)
      redirect_to admin_review_answers_path and return
    elsif !is_admin
      respond_to do |format|
        format.html { redirect_to signin_path and return }
        format.json { render :json => Common::ResultInfo.error_require_login and return }
      end
    end
    return true
  end

  def get_email
    _sign_out and return if session[:role].to_s.to_i==0
    render :json => BaseClient.new(session_info, "/users")._get({}, "/#{params[:id]}/get_email")
  end

  # just render json with variable @result
  def render_result
    _sign_out and return if @result.require_admin?
    render :json => @result
  end

  def render_404
    # render :text => "404"
    raise ActionController::RoutingError.new('Not Found')
  end
  
  def render_500
    raise '500 exception'
  end 

end