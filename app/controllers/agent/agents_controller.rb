# encoding: utf-8

class Agent::AgentsController < ApplicationController
  
  layout "agent-todc"

  before_filter :require_agent

  def require_agent
    session[:auth_key] == current_agent.try('auth_key')
  end

  def session_info
    session[:auth_key] ||= cookies[:auth_key]
    return Common::SessionInfo.new(session[:auth_key], request.remote_ip)
  end

  def current_agent
    unless @current_agent = Agent.find_by_auth_key(session[:auth_key])
      redirect_to "/agent/signin", :notice => "您需要登录才能继续操作!" and return
    end
    @current_agent
  end

  # just render json with variable @result
  def render_result
    _sign_out and return if @result.require_admin?
    render :json => @result
  end

end