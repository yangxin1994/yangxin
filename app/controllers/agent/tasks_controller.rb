class Agent::TasksController < Agent::AgentsController

  before_filter :get_task_client

  def get_task_client
    @task_client = Agent::TaskClient.new(session_info)
  end

  def index
    result = @task_client.index
    if result.success
      @tasks= result.value
      @tasks['host'] = request.host_with_port
    else
      render :json => result
    end
  end

  def show
    result = @task_client.show(params[:id])
    if result.success
      @task = result.value
    else
      render :json => result
    end
  end

  def close
    render :json => @task_client.close(params[:id])
  end
end