class Agent::AgentTasksController < Agent::ApplicationController
	before_filter :check_agent_task_existence, :only => [:close, :show]

	def check_agent_task_existence
		@agent_task = AgentTask.normal.find_by_id(params[:id])
		render_json_e(ErrorEnum::AGENT_TASK_NOT_EXIST) and return if @agent_task.nil?
	end

	def index
		@agent_tasks = AgentTask.search_agent_task(params[:agent_id], nil)
		@paginated_agent_tasks = auto_paginate(@agent_tasks) do |paginated_agent_tasks|
			paginated_agent_tasks.map { |e| e.info }
		end
		render_json_auto(@paginated_agent_tasks) and return
	end

	def show
		render_json_auto @agent_task.info and return
	end

	def close
		render_json_auto @agent_task.agent_close and return
	end
end