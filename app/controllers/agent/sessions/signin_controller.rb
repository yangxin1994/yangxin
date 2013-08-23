class Agent::Sessions::SigninController < Agent::AgentsController

  # PAGE: show sign in
  def index

  end

  def show
    
  end

  # AJAX: sign in
  def create
    result = Agent.login(params[:email], params[:password])
    
    if result == ErrorEnum::AGENT_NOT_EXIST || result == ErrorEnum::WRONG_PASSWORD
    	render :index
    else
    	refresh_session(result['auth_key'])
    	redirect_to '/agent/tasks'
    end
  end
  
end
