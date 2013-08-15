class Agent::ApplicationController < ApplicationController

	def require_agent
		@agent = Agent.find_by_auth_key(params[:auth_key])
		if @agent.nil?
			render_json_e(ErrorEnum::AGENT_NOT_EXIST) and return
		end
	end
end
