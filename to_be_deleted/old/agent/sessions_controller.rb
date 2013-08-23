require 'encryption'
require 'error_enum'
require 'tool'
class Agent::SessionsController < Agent::ApplicationController

  before_filter :require_agent, :only => [:reset_password]

  def create
    login = Agent.login(params[:agent]["email"], params[:agent]["password"])
    render_json_auto(login) and return
  end

  def destroy
    Agent.logout(params[:id])
    render_json_s and return
  end

  def reset_password
    retval = @agent.reset_password(params[:old_password], params[:new_password])
    render_json_auto(retval) and return
  end

  def login_with_auth_key
    retval = Agent.login_with_auth_key(params[:auth_key])
    render_json_auto(retval) and return
  end
end
