class Admin::AgentsController < Admin::AdminController

  layout "layouts/admin-todc"

  before_filter :require_sign_in, :only => [:index, :create, :update, :destroy]

  before_filter :get_agent_client

  def get_agent_client
    @agent_client = Admin::AgentClient.new(session_info)
  end

  def index
    result = @agent_client.index(params)
    if result.success
      @agents = result.value
    else
      render :json => result
    end
  end


  def new
    @agent = {}
  end

  def create
    @agent = @agent_client.create(params[:agent])
    if @agent.success
      redirect_to admin_agents_path
    else
      render :json => @agent
    end
  end

  def edit
    result = @agent_client.show(params[:id])
    if result.success
      @agent = result.value
    else
      render :json => result
    end
  end

  def update
    @agent = @agent_client.update(params[:id], params[:agent])
    if @agent.success
      redirect_to admin_agents_path
    else
      render :json => result
    end
  end

  def destroy
    render :json => @agent_client.destroy(params[:id])
  end


end
