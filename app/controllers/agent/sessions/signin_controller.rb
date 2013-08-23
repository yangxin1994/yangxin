# encoding: utf-8

class Agent::Sessions::SigninController < Agent::AgentsController

  before_filter :require_agent, :except => [:index, :create]

  # PAGE: show sign in
  def index

  end

  def show
    
  end

  # AJAX: sign in
  def create
    # render_json Agent.where(:email => params[:agent][:email], 
    #   :password => Encryption.encrypt_password(params[:agent][:password])).first do |agent|
    #   agent && agent.login
    # end
    begin
      auth_key = Agent.login(params[:agent][:email], params[:agent][:password])
    rescue Exception => e
      flash.alert = "用户名和密码不匹配!"
      render :index
    else
      session[:auth_key] = auth_key
      redirect_to agent_tasks_url, :flash => { :success => "登陆成功!" }
    end
  end
  
end
