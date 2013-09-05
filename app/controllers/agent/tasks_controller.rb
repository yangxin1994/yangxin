class Agent::TasksController < Agent::AgentsController

  def index
		# @tasks = auto_paginate(AgentTask.search_agent_task(params[:agent_id], nil)) do |tasks|
    @tasks = auto_paginate(current_agent.agent_tasks) do |tasks|
      tasks.map { |e| e.info }
    end
    @tasks['host'] = request.host_with_port
  end

  def show
    @task = current_agent.agent_tasks.find(params[:id])
  end

  def close
    render_json current_agent.agent_tasks.where(:_id => params[:id]).first do |agent|
      agent and agent.close
    end
  end
end
