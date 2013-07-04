class Agent::ApplicationController < ApplicationController

	def require_agent_task
		@agent_task = AgentTask.find_by_auth_key(params[:auth_key])
		if @agent_task.nil?
			render_json_e(ErrorEnum::AGENT_TASK_NOT_EXIST) and return
		end
	end
end
