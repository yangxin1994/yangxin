class Agent::Sessions::SigninController < Agent::AgentsController

  # PAGE: show sign in
  def index

  end

  def show
    
  end

  # AJAX: sign in
  def create
    result = Agent::SessionClient.new(session_info).login(params[:agent][:email], params[:agent][:password], params[:agent][:permanent_signed_in])
    if result.success
    	refresh_session(result.value['auth_key'])
    	redirect_to '/agent/tasks'
    else
    	render :index
    end
  end
  
end
