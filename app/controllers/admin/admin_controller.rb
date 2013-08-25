class Admin::AdminController < ApplicationController
  
  layout "admin"

  before_filter :require_sign_in
  # because only user_id of user is from return data in many times.
  # so add get_email method to replace user_id to email by AJAX.
  before_filter :require_admin, :except => [:get_email]

  def require_admin
  	if current_user.is_answer_auditor?
  		redirect_to admin_review_answers_path and return true
  	elsif !current_user.is_admin?
      respond_to do |format|
        format.html { _sign_out(request.url) and return false }
        format.json { render :json => Common::ResultInfo.error_require_login and return false }
      end
  	end
    return true
  end

  def get_email
    _sign_out and return if current_user.user_role==0
    render :json => BaseClient.new(session_info, "/users")._get({}, "/#{params[:id]}/get_email")
  end

  # just render json with variable @result
  def render_result
    _sign_out and return if @result.require_admin?
    render :json => @result
  end

end