class Agent::Sessions::SignoutController < Agent::AgentsController

  # PAGE: show sign in
  def index
    Agent.logout(current_agent._id)
    session[:auth_key] = ""
    redirect_to "/agent/signin"
  end

  # AJAX: sign in
end
