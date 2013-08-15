class Agent::Sessions::SigninController < Agent::AgentsController

  # PAGE: show sign in
  def index

  end

  def show
    
  end

  # AJAX: sign in
  def create
    result = Agent::SessionClient.new(session_info).login(params[:agent][:email], params[:agent][:password], params[:agent][:permanent_signed_in])
    session[:auth_key] = result.value['auth_key']
    cookies[:auth_key] = {
      :value => result.value['auth_key'],
      :expires => Rails.application.config.permanent_signed_in_months.months.from_now,
      :domain => :all
    }
    if result.success
      redirect_to '/agent/tasks'
    else
      render :index
    end
  end
  
end
