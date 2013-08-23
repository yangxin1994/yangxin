class Agent::Sessions::SigninController < Agent::AgentsController

  # PAGE: show sign in
  def index

  end

  def show
    
  end

  # AJAX: sign in
  def create
    Agent.login(params[:email], params[:password])
    
    refresh_session(result['auth_key'])
    if result.success
      redirect_to '/agent/tasks'
    else
      render :index
    end
  end
  
end
