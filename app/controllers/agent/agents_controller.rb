class Agent::AgentsController < ApplicationController
  
  layout "agent-todc"

  # because only user_id of user is from return data in many times.
  # so add get_email method to replace user_id to email by AJAX.
  before_filter :require_agent, :except => [:get_email]

  def require_agent
    # if !is_admin  # is_admin only check admin and super admin.
    true
  end

  def session_info
    session[:auth_key] ||= cookies[:auth_key]
    return Common::SessionInfo.new(session[:auth_key], request.remote_ip)
  end

  def current_agent
    @current_agent = session[:auth_key].nil? ? nil : Agent.find_by_auth_key(session[:auth_key])
    return @current_agent
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

end