# encoding: utf-8
# already tidied up

class Agent::Sessions::ResetPasswordController < Agent::AgentsController
  

  before_filter :require_agent, :only => [:index, :create]

  # PAGE: show sign in
  def index

  end

  def create
    if current_agent.reset_password(params[:agent][:password], params[:agent][:new_password])
      flash[:success] = "密码修改成功!"
      render :index
    else
      flash[:success] = "密码修改失败!"
    end
  end

end
