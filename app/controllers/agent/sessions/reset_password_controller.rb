class Agent::Sessions::ResetPasswordController < Agent::AgentsController
  

  before_filter :require_agent, :only => [:index, :update]

  before_filter :get_session_client

  def get_session_client
    @session_client = Agent::SessionClient.new(session_info)
  end  

  # PAGE: show sign in
  def index

  end

  def create
    result = @session_client.new_password(params[:agent][:password], params[:agent][:new_password], params[:agent][:password_confirmation] )
    refresh_session(result.value['auth_key'])
    render :json => result
  end

end
