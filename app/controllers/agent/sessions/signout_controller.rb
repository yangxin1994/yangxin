class Agent::Sessions::SignoutController < Agent::AgentsController
  
  before_filter :require_agent, :only => [:index]

  before_filter :get_session_client

  def get_session_client
    @session_client = Agent::SessionClient.new(session_info)
  end  

  # PAGE: show sign in
  def index
    @session_client.logout()
    redirect_to "/agent/signin"
  end

  # AJAX: sign in
end
